{{
    config(
        materialized='view',
        tags=['staging', 'scada', 'monitoring']
    )
}}

/*
    Model: stg_environment_data
    Description: SCADA环境监控数据原始数据清洗层 - Staging层
    Source: SCADA系统环境监控数据采集表
    Grain: 每行代表一条环境监控数据记录
*/

with source_data as (
    select * from {{ source('scada_raw', 'scada_environment_data') }}
),

final as (
    select
        data_id,
        location_id,
        parameter_name,
        parameter_value,
        unit,
        timestamp,
        data_quality,
        created_at
    from source_data
)

select * from final