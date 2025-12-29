{{
    config(
        materialized='view',
        tags=['staging', 'lims', 'quality']
    )
}}

/*
    Model: stg_sample
    Description: LIMS样品主数据原始数据清洗层 - Staging层
    Source: LIMS系统样品主数据表
    Grain: 每行代表一个样品
*/

with source_data as (
    select * from {{ source('lims_raw', 'lims_sample') }}
),

final as (
    select
        sample_id,
        sample_code,
        sample_type,
        sample_qty as sample_quantity,
        sample_unit,
        material_id, 
        batch_number,
        sample_date,
        sampler,
        storage_condition,
        location,
        expiry_date,
        sample_status,
        create_date
    from source_data
)

select * from final