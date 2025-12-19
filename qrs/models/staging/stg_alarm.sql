{{
    config(
        materialized='view',
        tags=['staging', 'scada', 'monitoring']
    )
}}

/*
    Model: stg_alarm
    Description: SCADA报警记录原始数据清洗层 - Staging层
    Source: SCADA系统报警记录表
    Grain: 每行代表一条报警记录
*/

with source_data as (
    select * from {{ source('scada_raw', 'scada_alarm') }}
),

final as (
    select
        alarm_id,
        equipment_id,
        location_code,
        alarm_type,
        alarm_level,
        alarm_message,
        alarm_time,
        ack_time,
        ack_by,
        resolve_time,
        resolve_by,
        alarm_status,
        related_batch,
        related_wo,
        created_at
    from source_data
)

select * from final