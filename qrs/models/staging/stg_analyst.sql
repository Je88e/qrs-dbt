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
        analyst_name,
        department,
        qualification,
        certification_date,
        analyst_status,
        created_at,
        updated_at
    from source_data
)

select * from final