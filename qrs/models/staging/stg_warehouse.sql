{{
    config(
        materialized='view',
        tags=['staging', 'erp', 'master_data']
    )
}}

/*
    Model: stg_warehouse
    Description: ERP仓库主数据原始数据清洗层 - Staging层
    Source: ERP系统仓库主数据表
    Grain: 每行代表一个仓库
*/

with source_data as (
    select * from {{ source('erp_raw', 'erp_warehouse') }}
),

final as (
    select
        warehouse_id,
        warehouse_name,
        warehouse_type,
        address,
        area as warehouse_area,
        manager,
        contact_phone,
        status as warehouse_status,
        create_date
    from source_data
)

select * from final