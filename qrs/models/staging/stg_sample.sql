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

renamed as (
    select
        sample_id,
        request_id,
        material_id,
        batch_number,
        sample_quantity,
        unit,
        sampling_date,
        sampler,
        sample_status,
        storage_location,
        expiry_date,
        created_at,
        updated_at
    from source_data
)

select * from renamed

