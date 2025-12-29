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

final as (
    select
        location_id,
        warehouse_id,
        location_code,
        location_name,
        location_type,
        capacity,
        capacity_unit,
        current_usage,
        status as location_status,
        create_date
    from source_data
)

select * from final