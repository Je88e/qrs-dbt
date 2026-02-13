{% macro get_snapshot_deleted_records(snapshot_name, source_schema, source_table, primary_key) %}
{#
    获取snapshot中标记为删除但源表中仍存在的记录

    参数:
        snapshot_name: snapshot表名 (如 'snap_material_receipts')
        source_schema: 源表schema (如 'raw')
        source_table: 源表名 (如 'erp_material_receipts')
        primary_key: 主键字段名 (如 'receipt_id')

    返回: 需要从源表删除的记录主键列表
#}

select
    snap.{{ primary_key }} as record_id,
    snap.dbt_valid_from,
    snap.dbt_valid_to,
    snap.dbt_updated_at,
    '{{ snapshot_name }}' as snapshot_source,
    '{{ source_schema }}.{{ source_table }}' as target_table,
    current_timestamp as identified_at
from {{ ref(snapshot_name) }} as snap
inner join {{ source_schema }}.{{ source_table }} as src
    on snap.{{ primary_key }} = src.{{ primary_key }}
where snap.dbt_is_deleted = 'True'
  and snap.dbt_valid_to is null  -- 当前有效的删除标记记录

{% endmacro %}
