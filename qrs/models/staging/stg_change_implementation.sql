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
        implementation_id,
        change_id,
        task_description,
        task_status,
        responsible_person,
        planned_date,
        actual_date,
        verification_result,
        created_at,
        updated_at
    from source_data
)

select * from final