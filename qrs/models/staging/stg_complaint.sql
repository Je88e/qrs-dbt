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
        complaint_code,
        complaint_type,
        complaint_source,
        product_id,
        batch_number,
        complaint_date,
        receive_date,
        complaint_description,
        contact_name,
        contact_phone,
        priority,
        status as complaint_status,
        investigator,
        investigation_result,
        corrective_action,
        response_date,
        close_date,
        create_date
    from source_data
)

select * from final