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
        report_code,
        sample_id,
        material_id,
        batch_number,
        conclusion,
        report_date,
        reporter,
        reviewer,
        review_date,
        approver,
        approval_date,
        status as report_status,
        create_date
    from source_data
)

select * from final