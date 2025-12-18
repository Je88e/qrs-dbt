{{
    config(
        materialized='view',
        tags=['staging', 'qms', 'quality']
    )
}}

/*
    Model: stg_deviation
    Description: QMS偏差记录原始数据清洗层 - Staging层
    Source: QMS系统偏差记录主表
    Grain: 每行代表一条偏差记录
*/

with source_data as (
    select * from {{ source('qms_raw', 'qms_deviation') }}
),

renamed as (
    select
        deviation_id,
        deviation_number,
        deviation_title,
        deviation_type,
        deviation_status,
        reporter,
        report_date,
        deviation_description,
        root_cause,
        corrective_action,
        closure_date,
        created_at,
        updated_at
    from source_data
)

select * from renamed

