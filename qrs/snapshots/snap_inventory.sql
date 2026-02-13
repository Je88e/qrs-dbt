{% snapshot snap_inventory %}

{{
    config(
        target_schema='snapshots',
        unique_key='inventory_id',
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
    Snapshot: snap_inventory
        Description: ERP库存主数据快照
        
        业务场景:
        - 库存状态变更追踪
        - 库存水平历史记录
        - 审计追踪
        
        运行频率: 每日
*/

select
    snowflake_id,
    inventory_id,
    material_id,
    batch_number,
    warehouse_id,
    location_id,
    current_quantity,
    unit,
    inventory_status,
    expiry_date,
    last_count_date,
    last_count_quantity,
    create_date, 
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_inventory') }}

{% endsnapshot %}
