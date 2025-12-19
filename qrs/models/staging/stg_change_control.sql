{{
    config(
        materialized='view',
        tags=['staging', 'qms', 'quality']
    )
}}

/*
    Model: stg_change_control
    Description: QMS变更控制原始数据清洗层 - Staging层
    Source: QMS系统变更控制主表
    Grain: 每行代表一个变更控制记录
*/

with source_data as (
    select * from {{ source('qms_raw', 'qms_change_control') }}
),

final as (
    select
        change_id,
        change_code,
        change_title,
        change_type,
        change_category,
        change_description,
        initiator,
        initiate_date,
        priority,
        status,
        planned_completion,
        actual_completion,
        reviewer,
        approver,
        approval_date,
        created_at
    from source_data
)

select * from final