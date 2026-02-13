{% snapshot snap_inventory_transaction %}

{{
    config(
        target_schema='snapshots',
        unique_key='transaction_id',
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
    Snapshot: snap_inventory_transaction
        Description: ERP库存交易记录快照
        
        业务场景:
        - 库存交易数据修正追踪
        - 库存变动历史记录
        - 审计追踪
        
        运行频率: 每日
*/

select
    snowflake_id,
    transaction_id,
    inventory_id,
    material_id,
    batch_number,
    transaction_type,
    transaction_quantity,
    transaction_unit,
    reference_doc,
    reference_type,
    operator_name,
    remark,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_inventory_transaction') }}

{% endsnapshot %}
