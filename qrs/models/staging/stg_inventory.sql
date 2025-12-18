{{
    config(
        materialized='view',
        tags=['staging', 'erp', 'inventory']
    )
}}

/*
    Model: stg_inventory
    Description: ERP库存主数据原始数据清洗层 - Staging层
    Source: ERP系统库存主数据表
    Grain: 每行代表一个库存记录
*/

with source_data as (
    select * from {{ source('erp_raw', 'erp_inventory') }}
),

renamed as (
    select
        inventory_id,
        material_id,
        batch_number,
        warehouse_id,
        location_id,
        quantity,
        unit,
        inventory_status,
        expiry_date,
        created_at,
        updated_at
    from source_data
)

select * from renamed

