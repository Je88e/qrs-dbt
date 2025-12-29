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

final as (
    select
        transaction_id,
        inventory_id,
        material_id,
        batch_number,
        transaction_type,
        quantity as transaction_quantity,
        unit as transaction_unit,
        transaction_date,
        reference_doc,
        reference_type,
        operator,
        remark,
        create_date
    from source_data
)

select * from final