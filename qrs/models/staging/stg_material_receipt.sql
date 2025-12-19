{{
    config(
        materialized='view',
        tags=['staging', 'erp', 'procurement', 'quality']
    )
}}

/*
    Model: stg_material_receipt
    Description: ERP物料接收记录原始数据清洗层 - Staging层
    Source: ERP系统物料接收记录表
    Grain: 每行代表一条物料接收记录
*/

with source_data as (
    select * from {{ source('erp_raw', 'erp_material_receipt') }}
),

final as (
    select
        -- 主键
        receipt_id,

        -- 外键
        po_number as purchase_order_number,
        material_id,
        warehouse_id,
        location_id,

        -- 批次信息
        batch_number,

        -- 数量信息
        receipt_qty as receipt_quantity,
        unit,

        -- 接收信息
        receipt_date,
        receiver,

        -- 检验状态
        inspection_status,

        -- 审计字段
        create_date as created_at

    from source_data
)

select * from final

