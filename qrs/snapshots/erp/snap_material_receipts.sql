{% snapshot snap_material_receipts %}

{{
    config(
        target_schema='snapshots',
        unique_key='receipt_id',
        strategy='timestamp',
        updated_at='create_date',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['snapshot', 'erp', 'audit', 'quality'],
        
        snapshot_meta_column_names={
            'dbt_valid_from': 'valid_from',
            'dbt_valid_to': 'valid_to',
            'dbt_scd_id': 'snapshot_id',
            'dbt_updated_at': 'last_updated_at',
            'dbt_is_deleted': 'is_deleted'
        }
    )
}}

/*
    Snapshot: snap_material_receipts
    Description: 物料接收状态变更快照 - 追踪检验状态变更
    
    业务场景:
    - 来料检验状态追踪
    - 物料放行时长分析
    - 质量合规审计
    
    追踪字段: inspection_status, inspection_result
    运行频率: 每日
*/

select
    -- 主键
    receipt_id,
    
    -- 外键
    purchase_order_number,
    material_id,
    warehouse_id,
    location_id,
    
    -- 批次信息
    batch_number,
    
    -- 数量信息
    receipt_quantity,
    unit,
    
    -- 接收信息
    receipt_date,
    receiver,
    
    -- 检验状态（核心追踪字段）
    inspection_status,
    inspection_result,
    
    -- 审计字段
    create_date
    
from {{ ref('stg_material_receipt') }}

{% endsnapshot %}

