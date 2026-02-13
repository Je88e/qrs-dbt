{% snapshot snap_purchase_order_detail %}

{{
    config(
        target_schema='snapshots',
        unique_key='purchase_order_detail_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['staging', 'erp', 'procurement', 'audit'],
        
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
        }
    )
}}

/*
    Snapshot: snap_purchase_order_detail
        Description: ERP采购订单明细快照
        
        业务场景:
        - 订单明细变更追踪
        - 采购明细历史记录
        - 审计追踪
        
        追踪字段: detail_status
        运行频率: 每日
*/

select
    snowflake_id,
    purchase_order_detail_id,
    purchase_order_number,
    material_id,
    quantity,
    unit,
    unit_price,
    amount,
    delivered_quantity,
    inspection_status,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_purchase_order_detail') }}

{% endsnapshot %}
