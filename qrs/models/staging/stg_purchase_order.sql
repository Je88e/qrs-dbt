{{
    config(
        materialized='view',
        tags=['staging', 'erp', 'procurement']
    )
}}

/*
    Model: stg_purchase_order
    Description: ERP采购订单原始数据清洗层 - Staging层
    Source: ERP系统采购订单主表
    Grain: 每行代表一个采购订单
*/

with source_data as (
    select * from {{ source('erp_raw', 'erp_purchase_order') }}
),

final as (
    select
        -- 主键
        po_number as purchase_order_number,

        -- 供应商信息
        supplier_id,

        -- 订单信息
        po_type as order_type,
        po_status as order_status,
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
        create_date as created_at,
        update_date as updated_at

    from source_data
)

select * from final

