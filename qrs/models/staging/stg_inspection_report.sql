{{
    config(
        materialized='view',
        tags=['staging', 'lims', 'quality']
    )
}}

/*
    Model: stg_inspection_report
    Description: LIMS检验报告原始数据清洗层 - Staging层
    Source: LIMS系统检验报告表
    Grain: 每行代表一份检验报告
*/

with source_data as (
    select * from {{ source('lims_raw', 'lims_inspection_report') }}
),

final as (
    select
        report_id,
        request_id,
        report_number,
        report_date,
        conclusion,
        reviewer,
        review_date,
        approver,
        approval_date,
        created_at,
        updated_at
    from source_data
)

select * from final