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
        material_name,
        quantity as material_quantity,
        unit as material_unit,
        sequence as material_sequence,
        is_critical,
        usage_notes,
        create_date
    from source_data
)

select * from final