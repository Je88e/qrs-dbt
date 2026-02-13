{% macro run_all_cleanups(dry_run=true, priority_filter=none) %}
{#
    批量执行所有配置的清洗任务

    参数:
        dry_run: 演练模式 (默认true)
        priority_filter: 只执行指定优先级的任务 (可选)

    使用方式:
        dbt run-operation run_all_cleanups --args '{dry_run: true}'
        dbt run-operation run_all_cleanups --args '{dry_run: false, priority_filter: 1}'
#}

{% set configs = get_cleanup_config() %}
{% set results = [] %}

{{ log("=" * 60, info=true) }}
{{ log("🧹 源表物理清洗任务开始", info=true) }}
{{ log("   模式: " ~ ("DRY RUN (预览)" if dry_run else "⚠️  LIVE (实际删除)"), info=true) }}
{{ log("=" * 60, info=true) }}

{% for config in configs | sort(attribute='priority') %}

    {# 检查是否启用 #}
    {% if not config.enabled %}
        {{ log("⏭️  跳过 " ~ config.snapshot_name ~ " (未启用)", info=true) }}
        {% continue %}
    {% endif %}

    {# 检查优先级过滤 #}
    {% if priority_filter is not none and config.priority != priority_filter %}
        {{ log("⏭️  跳过 " ~ config.snapshot_name ~ " (优先级不匹配)", info=true) }}
        {% continue %}
    {% endif %}

    {{ log("", info=true) }}
    {{ log("─" * 50, info=true) }}
    {{ log("处理: " ~ config.snapshot_name, info=true) }}
    {{ log("  源表: " ~ config.source_schema ~ "." ~ config.source_table, info=true) }}
    {{ log("  保留期: " ~ config.retention_days ~ " 天", info=true) }}

    {# 检查是否满足保留期要求 #}
    {% set retention_check_sql %}
        select count(*) as cnt
        from {{ ref(config.snapshot_name) }}
        where dbt_is_deleted = 'True'
          and dbt_valid_to is null
          and dbt_updated_at < current_timestamp - interval '{{ config.retention_days }} days'
    {% endset %}

    {% set eligible_count = run_query(retention_check_sql).columns[0].values()[0] %}

    {% if eligible_count == 0 %}
        {{ log("  ✅ 无符合保留期的待清洗记录", info=true) }}
        {% continue %}
    {% endif %}

    {{ log("  📊 符合清洗条件的记录: " ~ eligible_count, info=true) }}

    {# 执行清洗 #}
    {% set result = execute_source_cleanup(
        snapshot_name=config.snapshot_name,
        source_schema=config.source_schema,
        source_table=config.source_table,
        primary_key=config.primary_key,
        dry_run=dry_run
    ) %}

    {% do results.append({
        'snapshot': config.snapshot_name,
        'source': config.source_schema ~ '.' ~ config.source_table,
        'result': result
    }) %}

{% endfor %}

{{ log("", info=true) }}
{{ log("=" * 60, info=true) }}
{{ log("🏁 清洗任务完成", info=true) }}
{{ log("=" * 60, info=true) }}

{# 输出汇总 #}
{% for r in results %}
    {{ log("  " ~ r.snapshot ~ ": " ~ r.result.status ~
           (" (" ~ r.result.deleted_count ~ " 条)" if r.result.deleted_count else ""), info=true) }}
{% endfor %}

{{ return(results) }}

{% endmacro %}
