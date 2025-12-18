{{
    config(
        materialized='view',
        tags=['staging', 'erp', 'master_data']
    )
}}

/*
    Model: stg_storage_location
    Description: ERP库位主数据原始数据清洗层 - Staging层
    Source: ERP系统库位主数据表
    Grain: 每行代表一个库位
*/

with source_data as (
    select * from {{ source('erp_raw', 'erp_storage_location') }}
),

renamed as (
    select
        location_id,
        warehouse_id,
        location_code,
        location_name,
        location_type,
        capacity,
        location_status,
        created_at,
        updated_at
    from source_data
)

select * from renamed

