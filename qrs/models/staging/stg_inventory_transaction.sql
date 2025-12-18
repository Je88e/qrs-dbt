{{
    config(
        materialized='view',
        tags=['staging', 'erp', 'inventory']
    )
}}

/*
    Model: stg_inventory_transaction
    Description: ERP库存事务记录原始数据清洗层 - Staging层
    Source: ERP系统库存事务记录表
    Grain: 每行代表一条库存事务记录
*/

with source_data as (
    select * from {{ source('erp_raw', 'erp_inventory_transaction') }}
),

renamed as (
    select
        transaction_id,
        material_id,
        batch_number,
        warehouse_id,
        location_id,
        transaction_type,
        transaction_date,
        quantity,
        unit,
        reference_number,
        created_at
    from source_data
)

select * from renamed

