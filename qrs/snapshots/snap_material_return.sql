{% snapshot snap_material_return %}

{{
    config(
        target_schema='snapshots',
        unique_key='return_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['staging', 'erp', 'inventory', 'audit'],
        
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
        }
    )
}}

/*
    Snapshot: snap_material_return
        Description: ERP物料退料记录快照
        
        业务场景:
        - 退料状态变更追踪
        - 退料历史记录
        - 审计追踪
        
        追踪字段: return_status
        运行频率: 每日
*/

select
    snowflake_id,
    return_id,
    receipt_id,
    material_id,
    batch_number,
    return_quantity,
    unit,
    return_reason,
    return_type,
    return_date,
    return_status,
    supplier_id,
    processor,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_material_return') }}

{% endsnapshot %}
