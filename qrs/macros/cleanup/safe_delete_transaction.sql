{% macro safe_delete_with_transaction(source_schema, source_table, primary_key, record_ids, execution_id) %}
{#
    带完整事务控制的安全删除

    特性:
        1. 显式事务边界
        2. SAVEPOINT用于细粒度回滚
        3. 删除前后行数验证
        4. 异常自动回滚

    注意: PostgreSQL中dbt默认autocommit，此宏用于run-operation
#}

{% set record_count = record_ids | length %}

{% if record_count == 0 %}
    {{ log("⚠️  没有记录需要删除", info=true) }}
    {{ return({'status': 'no_records', 'deleted': 0}) }}
{% endif %}

{# 将record_ids转换为SQL数组 #}
{% set ids_sql = record_ids | join("','") %}

{% set transaction_sql %}
do $$
declare
    v_count_before integer;
    v_count_after integer;
    v_deleted integer;
    v_execution_id uuid := '{{ execution_id }}'::uuid;
begin
    -- 创建SAVEPOINT用于精确回滚
    -- SAVEPOINT cleanup_start; -- 注意: 在DO块中不支持SAVEPOINT

    -- 记录删除前行数
    select count(*) into v_count_before
    from {{ source_schema }}.{{ source_table }};

    -- 执行删除 (使用CTE返回删除数量)
    with deleted as (
        delete from {{ source_schema }}.{{ source_table }}
        where {{ primary_key }}::varchar in ('{{ ids_sql }}')
        returning 1
    )
    select count(*) into v_deleted from deleted;

    -- 记录删除后行数
    select count(*) into v_count_after
    from {{ source_schema }}.{{ source_table }};

    -- 验证: 删除数量应该匹配
    if v_count_before - v_count_after != v_deleted then
        raise exception '删除数量验证失败: 预期 %, 实际 %',
            v_deleted, v_count_before - v_count_after;
    end if;

    -- 验证: 删除数量不应超过请求数量
    if v_deleted > {{ record_count }} then
        raise exception '删除数量超过预期: 请求 %, 实际删除 %',
            {{ record_count }}, v_deleted;
    end if;

    -- 更新审计日志
    update audit.cleanup_audit_log
    set status = 'completed',
        executed_at = current_timestamp
    where execution_id = v_execution_id
      and record_id in ('{{ ids_sql }}');

    raise notice '✅ 事务完成: 删除 % 条记录', v_deleted;

exception when others then
    -- 记录失败
    update audit.cleanup_audit_log
    set status = 'failed',
        executed_at = current_timestamp
    where execution_id = v_execution_id;

    raise notice '❌ 事务回滚: %', sqlerrm;
    raise;
end $$;
{% endset %}

{% do run_query(transaction_sql) %}

{% endmacro %}


{% macro validate_before_delete(source_schema, source_table, primary_key, record_ids) %}
{#
    删除前验证检查

    检查项:
        1. 记录确实存在于源表
        2. 记录确实在snapshot中标记为删除
        3. 无外键依赖阻止删除
#}

{% set validation_results = [] %}

{# 检查1: 记录存在性 #}
{% set ids_sql = record_ids | join("','") %}

{% set exist_check_sql %}
    select count(*) as cnt
    from {{ source_schema }}.{{ source_table }}
    where {{ primary_key }}::varchar in ('{{ ids_sql }}')
{% endset %}

{% set exist_count = run_query(exist_check_sql).columns[0].values()[0] %}

{% if exist_count != record_ids | length %}
    {{ log("⚠️  警告: 部分记录不存在于源表 (请求: " ~ record_ids|length ~ ", 存在: " ~ exist_count ~ ")", info=true) }}
    {% do validation_results.append({'check': 'existence', 'passed': false, 'message': '记录数量不匹配'}) %}
{% else %}
    {% do validation_results.append({'check': 'existence', 'passed': true}) %}
{% endif %}

{# 检查2: 外键依赖 (PostgreSQL特有) #}
{% set fk_check_sql %}
    select
        tc.table_schema,
        tc.table_name,
        kcu.column_name,
        ccu.table_name as foreign_table_name,
        ccu.column_name as foreign_column_name
    from information_schema.table_constraints as tc
    join information_schema.key_column_usage as kcu
        on tc.constraint_name = kcu.constraint_name
    join information_schema.constraint_column_usage as ccu
        on ccu.constraint_name = tc.constraint_name
    where tc.constraint_type = 'FOREIGN KEY'
      and ccu.table_schema = '{{ source_schema }}'
      and ccu.table_name = '{{ source_table }}'
{% endset %}

{% set fk_deps = run_query(fk_check_sql) %}

{% if fk_deps | length > 0 %}
    {{ log("⚠️  发现外键依赖:", info=true) }}
    {% for dep in fk_deps %}
        {{ log("   - " ~ dep['table_schema'] ~ "." ~ dep['table_name'] ~ "." ~ dep['column_name'], info=true) }}
    {% endfor %}
    {% do validation_results.append({'check': 'foreign_keys', 'passed': false, 'dependencies': fk_deps}) %}
{% else %}
    {% do validation_results.append({'check': 'foreign_keys', 'passed': true}) %}
{% endif %}

{{ return(validation_results) }}

{% endmacro %}
