{{
    config(
        materialized='view',
        tags=['staging', 'erp', 'master_data']
    )
}}

/*
    Model: stg_formula_master
    Description: ERP配方主数据原始数据清洗层 - Staging层
    Source: ERP系统配方主数据表
    Grain: 每行代表一个配方
*/

with source_data as (
    select * from {{ source('erp_raw', 'erp_formula_master') }}
),

renamed as (
    select
        formula_id,
        formula_name,
        formula_version,
        product_id,
        formula_status,
        effective_date,
        expiry_date,
        created_at,
        updated_at
    from source_data
)

select * from renamed

