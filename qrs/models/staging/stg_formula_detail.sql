{{
    config(
        materialized='view',
        tags=['staging', 'erp', 'master_data']
    )
}}

/*
    Model: stg_formula_detail
    Description: ERP配方明细原始数据清洗层 - Staging层
    Source: ERP系统配方明细表
    Grain: 每行代表一个配方明细项
*/

with source_data as (
    select * from {{ source('erp_raw', 'erp_formula_detail') }}
),

final as (
    select
        formula_detail_id,
        formula_id,
        material_id,
        quantity,
        unit,
        sequence_number,
        created_at
    from source_data
)

select * from final