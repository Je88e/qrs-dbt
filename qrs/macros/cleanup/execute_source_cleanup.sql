{% macro execute_source_cleanup(snapshot_name, source_schema, source_table, primary_key, dry_run=true, batch_size=1000) %}
{#
    执行基于Snapshot删除标记的源表物理清洗

    参数:
        snapshot_name: snapshot表名
        source_schema: 源表schema
        source_table: 源表名
        primary_key: 主键字段
        dry_run: 是否为演练模式 (默认true，只预览不执行)
        batch_size: 批量删除大小 (防止长事务)

    安全机制:
        1. 默认dry_run模式
        2. 删除前写入审计日志
        3. 事务控制
        4. 批量处理避免锁表
#}

{% set audit_schema = 'audit' %}
{% set audit_table = 'cleanup_audit_log' %}

{# Step 1: 确保审计表存在 #}
{% set create_audit_sql %}
    create schema if not exists {{ audit_schema }};

    create table if not exists {{ audit_schema }}.{{ audit_table }} (
        audit_id serial primary key,
        execution_id uuid default gen_random_uuid(),
        snapshot_name varchar(255) not null,
        source_schema varchar(255) not null,
        source_table varchar(255) not null,
        primary_key_field varchar(255) not null,
        record_id varchar(255) not null,
        record_data jsonb,
        operation varchar(50) not null,
        executed_by varchar(255) default current_user,
        executed_at timestamp default current_timestamp,
        is_dry_run boolean not null,
        batch_number integer,
        status varchar(50) default 'pending'
    );

    create index if not exists idx_cleanup_audit_execution
        on {{ audit_schema }}.{{ audit_table }}(execution_id);
    create index if not exists idx_cleanup_audit_source
        on {{ audit_schema }}.{{ audit_table }}(source_schema, source_table);
{% endset %}

{% do run_query(create_audit_sql) %}

{# Step 2: 获取待删除记录 #}
{% set identify_sql %}
    select
        {{ primary_key }}::varchar as record_id,
        row_to_json(src.*)::jsonb as record_data
    from {{ source_schema }}.{{ source_table }} as src
    where exists (
        select 1
        from {{ ref(snapshot_name) }} as snap
        where snap.{{ primary_key }} = src.{{ primary_key }}
          and snap.dbt_is_deleted = 'True'
          and snap.dbt_valid_to is null
    )
{% endset %}

{% set records_to_delete = run_query(identify_sql) %}

{% if records_to_delete|length == 0 %}
    {{ log("✅ 没有找到需要清洗的记录", info=true) }}
    {{ return({'deleted_count': 0, 'status': 'no_records'}) }}
{% endif %}

{{ log("🔍 发现 " ~ records_to_delete|length ~ " 条待清洗记录", info=true) }}

{# Step 3: 生成执行ID用于追踪 #}
{% set execution_id_sql %}
    select gen_random_uuid()::varchar as exec_id
{% endset %}
{% set execution_id = run_query(execution_id_sql).columns[0].values()[0] %}

{{ log("📋 执行ID: " ~ execution_id, info=true) }}

{# Step 4: 写入审计日志 (删除前备份) #}
{% set audit_insert_sql %}
    insert into {{ audit_schema }}.{{ audit_table }} (
        execution_id,
        snapshot_name,
        source_schema,
        source_table,
        primary_key_field,
        record_id,
        record_data,
        operation,
        is_dry_run,
        status
    )
    select
        '{{ execution_id }}'::uuid,
        '{{ snapshot_name }}',
        '{{ source_schema }}',
        '{{ source_table }}',
        '{{ primary_key }}',
        {{ primary_key }}::varchar,
        row_to_json(src.*)::jsonb,
        'DELETE',
        {{ dry_run }},
        {% if dry_run %}'dry_run'{% else %}'pending'{% endif %}
    from {{ source_schema }}.{{ source_table }} as src
    where exists (
        select 1
        from {{ ref(snapshot_name) }} as snap
        where snap.{{ primary_key }} = src.{{ primary_key }}
          and snap.dbt_is_deleted = 'True'
          and snap.dbt_valid_to is null
    )
{% endset %}

{% do run_query(audit_insert_sql) %}
{{ log("💾 审计日志已写入", info=true) }}

{# Step 5: 执行删除 (仅非dry_run模式) #}
{% if dry_run %}
    {{ log("⚠️  DRY RUN 模式 - 未执行实际删除", info=true) }}
    {{ log("   要执行实际删除，请设置 dry_run=false", info=true) }}

    {# 显示将被删除的记录预览 #}
    {% set preview_sql %}
        select record_id, record_data->>'{{ primary_key }}' as pk_value
        from {{ audit_schema }}.{{ audit_table }}
        where execution_id = '{{ execution_id }}'::uuid
        limit 10
    {% endset %}

    {% set preview = run_query(preview_sql) %}
    {{ log("   预览待删除记录 (前10条):", info=true) }}
    {% for row in preview %}
        {{ log("   - " ~ row['record_id'], info=true) }}
    {% endfor %}

    {{ return({'deleted_count': 0, 'records_identified': records_to_delete|length, 'execution_id': execution_id, 'status': 'dry_run'}) }}

{% else %}
    {# 实际删除 - 使用批量处理 #}
    {{ log("🗑️  开始执行物理删除...", info=true) }}

    {% set delete_sql %}
        with deleted_records as (
            delete from {{ source_schema }}.{{ source_table }}
            where {{ primary_key }} in (
                select (record_data->>'{{ primary_key }}')::{{ get_pk_type(source_schema, source_table, primary_key) }}
                from {{ audit_schema }}.{{ audit_table }}
                where execution_id = '{{ execution_id }}'::uuid
                  and status = 'pending'
                limit {{ batch_size }}
            )
            returning {{ primary_key }}
        )
        update {{ audit_schema }}.{{ audit_table }}
        set status = 'completed',
            executed_at = current_timestamp
        where execution_id = '{{ execution_id }}'::uuid
          and record_id in (select {{ primary_key }}::varchar from deleted_records)
    {% endset %}

    {# 循环批量删除 #}
    {% set total_deleted = 0 %}
    {% set batch_num = 0 %}

    {% set pending_count_sql %}
        select count(*) as cnt
        from {{ audit_schema }}.{{ audit_table }}
        where execution_id = '{{ execution_id }}'::uuid
          and status = 'pending'
    {% endset %}

    {% set pending = run_query(pending_count_sql).columns[0].values()[0] %}

    {% for i in range(((pending / batch_size)|int) + 1) %}
        {% set batch_num = i + 1 %}

        {% set batch_delete_sql %}
            with to_delete as (
                select record_id
                from {{ audit_schema }}.{{ audit_table }}
                where execution_id = '{{ execution_id }}'::uuid
                  and status = 'pending'
                limit {{ batch_size }}
            ),
            deleted as (
                delete from {{ source_schema }}.{{ source_table }} src
                using to_delete td
                where src.{{ primary_key }}::varchar = td.record_id
                returning src.{{ primary_key }}
            )
            update {{ audit_schema }}.{{ audit_table }} al
            set status = 'completed',
                batch_number = {{ batch_num }},
                executed_at = current_timestamp
            from deleted d
            where al.execution_id = '{{ execution_id }}'::uuid
              and al.record_id = d.{{ primary_key }}::varchar
        {% endset %}

        {% do run_query(batch_delete_sql) %}
        {{ log("   批次 " ~ batch_num ~ " 完成", info=true) }}
    {% endfor %}

    {# 统计已删除数量 #}
    {% set completed_count_sql %}
        select count(*) as cnt
        from {{ audit_schema }}.{{ audit_table }}
        where execution_id = '{{ execution_id }}'::uuid
          and status = 'completed'
    {% endset %}

    {% set deleted_count = run_query(completed_count_sql).columns[0].values()[0] %}

    {{ log("✅ 清洗完成: 删除 " ~ deleted_count ~ " 条记录", info=true) }}
    {{ log("   执行ID: " ~ execution_id ~ " (可用于回滚查询)", info=true) }}

    {{ return({'deleted_count': deleted_count, 'execution_id': execution_id, 'status': 'completed'}) }}
{% endif %}

{% endmacro %}


{% macro get_pk_type(schema, table, column) %}
    {# 获取主键字段类型 #}
    {% set type_sql %}
        select data_type
        from information_schema.columns
        where table_schema = '{{ schema }}'
          and table_name = '{{ table }}'
          and column_name = '{{ column }}'
    {% endset %}
    {% set result = run_query(type_sql) %}
    {% if result|length > 0 %}
        {{ return(result.columns[0].values()[0]) }}
    {% else %}
        {{ return('varchar') }}
    {% endif %}
{% endmacro %}
