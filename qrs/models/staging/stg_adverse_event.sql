{{
    config(
        materialized='view',
        tags=['staging', 'pv', 'safety']
    )
}}

/*
    Model: stg_adverse_event
    Description: PV不良反应报告原始数据清洗层 - Staging层
    Source: PV系统不良反应报告表
    Grain: 每行代表一条不良反应报告
*/

with source_data as (
    select * from {{ source('pv_raw', 'pv_adverse_event') }}
),

renamed as (
    select
        event_id,
        event_number,
        product_id,
        batch_number,
        event_type,
        severity,
        event_date,
        report_date,
        reporter,
        patient_info,
        event_description,
        investigation_status,
        created_at,
        updated_at
    from source_data
)

select * from renamed

