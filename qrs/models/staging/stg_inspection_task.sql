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
        test_item_id,
        analyst_id,
        task_status,
        assigned_date,
        start_date,
        completion_date,
        created_at,
        updated_at
    from source_data
)

select * from final