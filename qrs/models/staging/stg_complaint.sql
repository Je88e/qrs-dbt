{{
    config(
        materialized='view',
        tags=['staging', 'pv', 'quality']
    )
}}

/*
    Model: stg_complaint
    Description: PV产品投诉记录原始数据清洗层 - Staging层
    Source: PV系统产品投诉记录表
    Grain: 每行代表一条产品投诉记录
*/

with source_data as (
    select * from {{ source('pv_raw', 'pv_complaint') }}
),

final as (
    select
        complaint_id,
        complaint_number,
        product_id,
        batch_number,
        complaint_type,
        complaint_date,
        complainant,
        complaint_description,
        investigation_result,
        resolution,
        closure_date,
        created_at,
        updated_at
    from source_data
)

select * from final