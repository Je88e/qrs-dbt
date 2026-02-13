{{
    config(
        materialized='view',
        schema='audit'
    )
}}

{#
    清洗候选记录预览视图
    用于监控哪些记录将在下次清洗中被删除
#}

{% set configs = get_cleanup_config() %}

{% for config in configs %}
{% if config.enabled %}

select
    '{{ config.snapshot_name }}' as snapshot_name,
    '{{ config.source_schema }}.{{ config.source_table }}' as source_table,
    '{{ config.primary_key }}' as primary_key_field,
    snap.{{ config.primary_key }}::varchar as record_id,
    snap.dbt_updated_at as deleted_marked_at,
    current_timestamp - snap.dbt_updated_at as age,
    {{ config.retention_days }} as retention_days,
    case
        when snap.dbt_updated_at < current_timestamp - interval '{{ config.retention_days }} days'
        then true
        else false
    end as eligible_for_cleanup,
    snap.dbt_updated_at + interval '{{ config.retention_days }} days' as cleanup_eligible_date
from {{ ref(config.snapshot_name) }} as snap
inner join {{ config.source_schema }}.{{ config.source_table }} as src
    on snap.{{ config.primary_key }} = src.{{ config.primary_key }}
where snap.dbt_is_deleted = 'True'
  and snap.dbt_valid_to is null

{% if not loop.last %}union all{% endif %}

{% endif %}
{% endfor %}
