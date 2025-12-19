{{
    config(
        materialized='view',
        tags=['staging', 'erp', 'master_data']
    )
}}

/*
    Model: stg_material_master
    Description: ERP物料主数据原始数据清洗层 - Staging层
    Source: ERP系统物料主数据表
    Grain: 每行代表一个物料
*/

with source_data as (
    select * from {{ source('erp_raw', 'erp_material_master') }}
),

final as (
    select
        -- 主键
        material_id,
        
        -- 物料信息
        material_name,
        material_type,
        specification,
        unit,
        
        -- 供应商信息
        supplier_id,
        
        -- 状态信息
        approval_status,
        is_deleted,
        
        -- 审计字段
        create_date as created_at,
        update_date as updated_at
        
    from source_data
)

select * from final