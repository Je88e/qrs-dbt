{{
    config(
        materialized='view',
        tags=['staging', 'erp', 'procurement', 'quality']
    )
}}

/*
    Model: stg_material_return
    Description: ERP物料退货记录原始数据清洗层 - Staging层
    Source: ERP系统物料退货记录表
    Grain: 每行代表一条物料退货记录
*/

with source_data as (
    select * from {{ source('erp_raw', 'erp_material_return') }}
),

final as (
    select
        -- 主键
        return_id,
        
        -- 外键
        receipt_id,
        material_id,
        
        -- 批次信息
        batch_number,
        
        -- 数量信息
        return_qty as return_quantity,
        unit,
        
        -- 退货信息
        return_date,
        return_reason,
        return_status,
        handler,
        
        -- 审计字段
        create_date as created_at
        
    from source_data
)

select * from final