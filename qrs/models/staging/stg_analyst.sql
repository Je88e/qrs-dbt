{{
    config(
        materialized='view',
        tags=['staging', 'lims', 'master_data']
    )
}}

/*
    Model: stg_analyst
    Description: LIMS分析员主数据原始数据清洗层 - Staging层
    Source: LIMS系统分析员主数据表
    Grain: 每行代表一个分析员
*/

with source_data as (
    select * from {{ source('lims_raw', 'lims_analyst') }}
),

final as (
    select
        analyst_id,
        analyst_code,
        analyst_name,
        department,
        qualification,
        certification_date,
        certification_expiry,
        status as analyst_status,
        create_date
    from source_data
)

select * from final