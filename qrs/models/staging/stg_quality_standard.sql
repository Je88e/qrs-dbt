{{
    config(
        materialized='view',
        tags=['staging', 'lims', 'master_data']
    )
}}

/*
    Model: stg_quality_standard
    Description: LIMS质量标准主数据原始数据清洗层 - Staging层
    Source: LIMS系统质量标准主表
    Grain: 每行代表一个质量标准
*/

with source_data as (
    select * from {{ source('lims_raw', 'lims_quality_standard') }}
),

renamed as (
    select
        standard_id,
        material_id,
        standard_name,
        standard_version,
        standard_status,
        effective_date,
        expiry_date,
        created_at,
        updated_at
    from source_data
)

select * from renamed

