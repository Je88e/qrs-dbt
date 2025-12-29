{% snapshot snap_purchase_orders %}

{{
    config(
        target_schema='snapshots',
        unique_key='purchase_order_number',
        strategy='timestamp',
        updated_at='update_date',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['snapshot', 'erp', 'audit', 'compliance'],
        
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
    Snapshot: snap_purchase_orders
    Description: 采购订单状态变更快照 - 追踪订单全生命周期
    
    业务场景:
    - 订单审批流程追踪
    - 订单处理时长分析
    - 合规审计支持
    - 状态变更历史查询
    
    追踪字段: order_status, approval_date, actual_delivery_date
    运行频率: 每日
*/

select
    -- 主键
    purchase_order_number,
    
    -- 供应商信息
    supplier_id,
    
    -- 订单信息
    order_type,
    order_status,
    order_date,
    expected_delivery_date,
    actual_delivery_date,
    
    -- 金额信息
    total_amount,
    currency,
    
    -- 审批信息
    buyer,
    approver,
    approval_date,
    
    -- 审计字段
    create_date,
    -- 处理 NULL 值：如果 update_date 为 NULL，使用 create_date
    coalesce(update_date, create_date) as update_date

from {{ ref('stg_purchase_order') }}

{% endsnapshot %}

