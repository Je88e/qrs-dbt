{{
    config(
        materialized='view',
        tags=['staging', 'erp', 'procurement']
    )
}}

/*
    Model: stg_purchase_order_detail
    Description: ERP采购订单明细原始数据清洗层 - Staging层
    Source: ERP系统采购订单明细表
    Grain: 每行代表一个采购订单明细项
*/

with source_data as (
    select * from {{ source('erp_raw', 'erp_purchase_order_detail') }}
),

renamed as (
    select
        -- 主键
        pod_id as purchase_order_detail_id,
        
        -- 外键
        po_number as purchase_order_number,
        material_id,
        
        -- 数量和金额
        quantity,
        unit,
        unit_price,
        amount,
        
        -- 交付信息
        delivery_qty as delivered_quantity,
        inspection_status
        
    from source_data
)

select * from renamed

