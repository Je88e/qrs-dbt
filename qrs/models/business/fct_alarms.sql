{{
    config(
        materialized='view',
        tags=['scada', 'alarm', 'monitoring', 'pqr']
    )
}}

/*
    Model: fct_alarms
    Description: 提供设备和环境报警的管理信息
*/

with alarm as (
    select * from {{ ref('stg_alarm') }}
),

equipment as (
    select * from {{ ref('stg_equipment') }}
),

work_order as (
    select * from {{ ref('stg_work_order') }}
)

select
    -- 报警主键
    a.alarm_id,
    
    -- 设备信息
    a.equipment_id,
    eq.equipment_code,
    eq.equipment_name,
    
    -- 位置信息
    a.location_code,
    
    -- 报警信息
    a.alarm_type,
    a.alarm_level,
    a.alarm_message,
    
    -- 时间信息
    a.alarm_time,
    a.acknowledge_time,
    a.acknowledged_by,
    a.resolve_time,
    a.resolved_by,
    
    -- 报警状态
    a.alarm_status,
    
    -- 关联生产信息
    a.batch_number,
    a.work_order_number,
    wo.product_id,
    
    -- 响应时间（分钟）
    case
        when a.acknowledge_time is not null and a.alarm_time is not null
        then {{ timestamp_diff_minutes('a.acknowledge_time', 'a.alarm_time') }}
        else null
    end as response_time_minutes,

    -- 解决时间（分钟）
    case
        when a.resolve_time is not null and a.alarm_time is not null
        then {{ timestamp_diff_minutes('a.resolve_time', 'a.alarm_time') }}
        else null
    end as resolution_time_minutes,
    
    -- 审计字段
    a.create_date

from alarm a
left join equipment eq on a.equipment_id = eq.equipment_id
left join work_order wo on a.work_order_number = wo.work_order_number

