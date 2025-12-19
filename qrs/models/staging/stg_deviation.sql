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

final as (
    select
        deviation_id,
        deviation_code,
        deviation_title,
        deviation_type,
        deviation_category,
        product_id,
        batch_number,
        occurrence_date,
        discovery_date,
        deviation_description,
        immediate_action,
        root_cause,
        corrective_action,
        preventive_action,
        status,
        investigator,
        reviewer,
        approver,
        close_date,
        created_at,
        updated_at
    from source_data
)

select * from final