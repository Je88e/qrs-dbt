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

final as (
    select
        standard_id,
        standard_code,
        standard_name,
        material_type,
        version as standard_version,
        effective_date,
        expiry_date,
        status as standard_status,
        creator,
        approver,
        approval_date,
        create_date
    from source_data
)

select * from final