{% snapshot snap_formula_detail %}

{{
    config(
        target_schema='snapshots',
        unique_key='formula_detail_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['staging', 'erp', 'production', 'audit'],
        
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
        }
    )
}}

/*
    Snapshot: snap_formula_detail
        Description: ERP配方明细快照
        
        业务场景:
        - 配方明细变更追踪
        - 配方版本历史记录
        - 审计追踪
        
        运行频率: 每日
*/

select
    snowflake_id,
    formula_detail_id,
    formula_id,
    material_id,
    material_name,
    material_quantity,
    material_unit,
    material_sequence,
    is_critical,
    usage_notes,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_formula_detail') }}

{% endsnapshot %}
