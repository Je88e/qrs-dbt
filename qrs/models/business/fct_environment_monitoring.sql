{{
    config(
        materialized='view',
        tags=['scada', 'environment', 'monitoring', 'pqr']
    )
}}

/*
    Model: fct_environment_monitoring
    Description: 提供生产环境的温湿度、压差等监控数据
*/

with environment_data as (
    select * from {{ ref('stg_environment_data') }}
)

select
    -- 数据主键
    data_id,
    
    -- 位置信息
    location_code,
    location_name,
    
    -- 环境参数
    temperature,
    humidity,
    pressure_difference,
    particle_count,
    
    -- 采集时间
    collection_time,
    
    -- 状态
    monitoring_status,
    
    -- 温度是否超标 (假设标准范围18-26℃)
    case 
        when temperature < 18 or temperature > 26 then true
        else false
    end as temperature_out_of_range,
    
    -- 湿度是否超标 (假设标准范围35-65%)
    case 
        when humidity < 35 or humidity > 65 then true
        else false
    end as humidity_out_of_range,
    
    -- 审计字段
    create_date

from environment_data

