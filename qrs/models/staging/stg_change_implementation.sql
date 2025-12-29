{{
    config(
        materialized='view',
        tags=['staging', 'qms', 'quality']
    )
}}

/*
    Model: stg_change_implementation
    Description: QMS变更实施记录原始数据清洗层 - Staging层
    Source: QMS系统变更实施记录表
    Grain: 每行代表一条变更实施任务记录
*/

with source_data as (
    select * from {{ source('qms_raw', 'qms_change_implementation') }}
),

final as (
    select
        impl_id as implementation_id,
        change_id,
        task_name,
        task_description,
        responsible,
        planned_start,
        planned_end,
        actual_start,
        actual_end,
        status as task_status,
        completion_evidence,
        reviewer,
        review_date,
        create_date
    from source_data
)

select * from final