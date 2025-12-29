{{
    config(
        materialized='view',
        tags=['staging', 'lims', 'quality']
    )
}}

/*
    Model: stg_inspection_task
    Description: LIMS检验任务原始数据清洗层 - Staging层
    Source: LIMS系统检验任务表
    Grain: 每行代表一个检验任务
*/

with source_data as (
    select * from {{ source('lims_raw', 'lims_inspection_task') }}
),

final as (
    select
        task_id,
        request_id,
        sample_id,
        test_item_id,
        assigned_analyst,
        assigned_date,
        planned_completion,
        actual_completion,
        task_status,
        priority,
        equipment_id,
        create_date
    from source_data
)

select * from final