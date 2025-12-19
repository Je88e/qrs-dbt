{{
    config(
        materialized='view',
        tags=['staging', 'scada', 'production']
    )
}}

/*
    Model: stg_batch_tracking
    Description: SCADA批次追踪记录原始数据清洗层 - Staging层
    Source: SCADA系统批次追踪记录表
    Grain: 每行代表一条批次追踪记录
*/

with source_data as (
    select * from {{ source('scada_raw', 'scada_batch_tracking') }}
),

final as (
    select
        tracking_id,
        batch_number,
        equipment_id,
        process_step,
        start_time,
        end_time,
        process_parameters,
        operator_id,
        created_at
    from source_data
)

select * from final