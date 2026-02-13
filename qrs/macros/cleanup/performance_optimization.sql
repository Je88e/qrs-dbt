{% macro optimize_cleanup_performance(source_schema, source_table, primary_key) %}
{#
    PostgreSQL清洗性能优化

    优化策略:
        1. 批量删除避免长事务
        2. 使用临时表加速IN查询
        3. 删除后维护表统计信息
        4. 索引优化建议
#}

{# 创建临时索引加速删除 (如果不存在) #}
{% set create_index_sql %}
    create index if not exists idx_cleanup_{{ source_table }}_{{ primary_key }}
        on {{ source_schema }}.{{ source_table }}({{ primary_key }});
{% endset %}

{% do run_query(create_index_sql) %}

{% endmacro %}


{% macro batch_delete_optimized(source_schema, source_table, primary_key, snapshot_name, batch_size=5000) %}
{#
    优化的批量删除 - 使用临时表和批处理

    性能特点:
        1. 使用UNLOGGED临时表避免WAL开销
        2. 分批删除减少锁竞争
        3. 利用索引扫描
        4. 自动VACUUM ANALYZE
#}

{% set setup_sql %}
    -- 创建临时表存储待删除ID
    create temp table if not exists _cleanup_batch_ids (
        record_id varchar(255) primary key,
        batch_num integer
    ) on commit drop;

    -- 清空并填充
    truncate _cleanup_batch_ids;

    insert into _cleanup_batch_ids (record_id, batch_num)
    select
        snap.{{ primary_key }}::varchar,
        ntile(ceil(count(*) over() / {{ batch_size }}::float)::int) over (order by snap.{{ primary_key }})
    from {{ ref(snapshot_name) }} as snap
    inner join {{ source_schema }}.{{ source_table }} as src
        on snap.{{ primary_key }} = src.{{ primary_key }}
    where snap.dbt_is_deleted = 'True'
      and snap.dbt_valid_to is null;
{% endset %}

{% do run_query(setup_sql) %}

{# 获取批次数 #}
{% set batch_count_sql %}
    select coalesce(max(batch_num), 0) as max_batch from _cleanup_batch_ids
{% endset %}
{% set max_batch = run_query(batch_count_sql).columns[0].values()[0] %}

{{ log("📊 分为 " ~ max_batch ~ " 个批次执行删除", info=true) }}

{# 逐批删除 #}
{% for batch_num in range(1, max_batch + 1) %}

    {% set delete_batch_sql %}
        delete from {{ source_schema }}.{{ source_table }} as t
        using _cleanup_batch_ids as b
        where t.{{ primary_key }}::varchar = b.record_id
          and b.batch_num = {{ batch_num }};
    {% endset %}

    {% do run_query(delete_batch_sql) %}
    {{ log("  批次 " ~ batch_num ~ "/" ~ max_batch ~ " 完成", info=true) }}

    {# 每10批执行一次checkpoint建议 #}
    {% if batch_num % 10 == 0 %}
        {% set checkpoint_sql %}
            -- 提示PostgreSQL可以进行checkpoint (不强制)
            select pg_stat_reset_single_table_counters(
                '{{ source_schema }}.{{ source_table }}'::regclass
            );
        {% endset %}
        {# 此操作可选，需要superuser权限 #}
    {% endif %}

{% endfor %}

{# 删除后维护 #}
{% set maintenance_sql %}
    -- 更新表统计信息
    analyze {{ source_schema }}.{{ source_table }};
{% endset %}

{% do run_query(maintenance_sql) %}
{{ log("✅ 表统计信息已更新", info=true) }}

{% endmacro %}


{% macro cleanup_performance_report(source_schema, source_table) %}
{#
    生成清洗操作的性能报告
#}

{% set report_sql %}
    select
        schemaname,
        relname as table_name,
        n_tup_del as tuples_deleted,
        n_dead_tup as dead_tuples,
        last_vacuum,
        last_autovacuum,
        last_analyze,
        pg_size_pretty(pg_total_relation_size(schemaname || '.' || relname)) as table_size
    from pg_stat_user_tables
    where schemaname = '{{ source_schema }}'
      and relname = '{{ source_table }}'
{% endset %}

{% set report = run_query(report_sql) %}

{{ log("📊 性能报告 - " ~ source_schema ~ "." ~ source_table, info=true) }}
{% for row in report %}
    {{ log("   已删除元组: " ~ row['tuples_deleted'], info=true) }}
    {{ log("   死亡元组: " ~ row['dead_tuples'], info=true) }}
    {{ log("   最后VACUUM: " ~ row['last_vacuum'], info=true) }}
    {{ log("   表大小: " ~ row['table_size'], info=true) }}
{% endfor %}

{# 如果死亡元组过多，建议VACUUM #}
{% if report[0]['dead_tuples'] | int > 10000 %}
    {{ log("⚠️  建议执行: VACUUM ANALYZE " ~ source_schema ~ "." ~ source_table, info=true) }}
{% endif %}

{% endmacro %}
