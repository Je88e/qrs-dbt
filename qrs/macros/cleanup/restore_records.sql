{% macro restore_deleted_records(execution_id) %}
{#
    从审计日志恢复已删除的记录

    参数:
        execution_id: 执行ID (由cleanup操作生成)

    使用方式:
        dbt run-operation restore_deleted_records --args '{execution_id: "xxx-xxx-xxx"}'
#}

{{ log("🔄 开始恢复执行ID: " ~ execution_id, info=true) }}

{# 获取执行信息 #}
{% set info_sql %}
    select
        source_schema,
        source_table,
        primary_key_field,
        count(*) as record_count,
        min(executed_at) as executed_at
    from audit.cleanup_audit_log
    where execution_id = '{{ execution_id }}'::uuid
      and status = 'completed'
    group by source_schema, source_table, primary_key_field
{% endset %}

{% set exec_info = run_query(info_sql) %}

{% if exec_info | length == 0 %}
    {{ log("❌ 未找到执行ID: " ~ execution_id, info=true) }}
    {{ return({'status': 'not_found'}) }}
{% endif %}

{% set source_schema = exec_info.columns['source_schema'].values()[0] %}
{% set source_table = exec_info.columns['source_table'].values()[0] %}
{% set record_count = exec_info.columns['record_count'].values()[0] %}

{{ log("   源表: " ~ source_schema ~ "." ~ source_table, info=true) }}
{{ log("   记录数: " ~ record_count, info=true) }}

{# 从JSONB恢复数据 #}
{% set restore_sql %}
    insert into {{ source_schema }}.{{ source_table }}
    select (jsonb_populate_record(
        null::{{ source_schema }}.{{ source_table }},
        record_data
    )).*
    from audit.cleanup_audit_log
    where execution_id = '{{ execution_id }}'::uuid
      and status = 'completed'
    on conflict do nothing
    returning 1
{% endset %}

{% set restored = run_query(restore_sql) %}
{% set restored_count = restored | length %}

{# 更新审计日志状态 #}
{% set update_status_sql %}
    update audit.cleanup_audit_log
    set status = 'restored',
        executed_at = current_timestamp
    where execution_id = '{{ execution_id }}'::uuid
      and status = 'completed'
{% endset %}

{% do run_query(update_status_sql) %}

{{ log("✅ 恢复完成: " ~ restored_count ~ " 条记录", info=true) }}

{{ return({'status': 'restored', 'count': restored_count}) }}

{% endmacro %}


{% macro list_cleanup_executions(days_back=30) %}
{#
    列出最近的清洗执行记录
#}

{% set sql %}
    select
        execution_id,
        source_schema || '.' || source_table as source,
        count(*) as record_count,
        min(executed_at) as executed_at,
        array_agg(distinct status) as statuses
    from audit.cleanup_audit_log
    where executed_at > current_timestamp - interval '{{ days_back }} days'
    group by execution_id, source_schema, source_table
    order by min(executed_at) desc
    limit 50
{% endset %}

{% set executions = run_query(sql) %}

{{ log("📋 最近 " ~ days_back ~ " 天的清洗执行:", info=true) }}
{{ log("─" * 80, info=true) }}

{% for row in executions %}
    {{ log(row['execution_id'] ~ " | " ~
           row['source'] ~ " | " ~
           row['record_count'] ~ " 条 | " ~
           row['executed_at'] ~ " | " ~
           row['statuses'], info=true) }}
{% endfor %}

{% endmacro %}
