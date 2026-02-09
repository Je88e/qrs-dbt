{{
    config(
        materialized='view',
        tags=['mes', 'equipment', 'calibration', 'pqr']
    )
}}

/*
    Model: fct_equipment_calibration
    Description: 设备校准记录 - 提供设备校准状态和合规性视图
*/

with calibration as (
    select * from {{ ref('stg_equipment_calibration') }}
),

equipment as (
    select * from {{ ref('stg_equipment') }}
),

workshop as (
    select * from {{ ref('stg_workshop') }}
)

select
    -- 校准主键
    c.calibration_id,
    c.calibration_code,

    -- 设备信息
    c.equipment_id,
    e.equipment_code,
    e.equipment_name,
    e.equipment_type,
    e.manufacturer,

    -- 车间信息
    e.workshop_id,
    w.workshop_name,

    -- 校准信息
    c.calibration_type,
    c.calibration_date,
    c.next_calibration_date,
    c.calibration_cycle,

    -- 标准器信息
    c.standard_equipment,
    c.standard_certificate,

    -- 校准结果
    c.calibration_result,
    c.deviation_value,
    c.tolerance,
    c.is_within_tolerance,

    -- 校准状态计算
    c.calibration_status,
    case
        when c.next_calibration_date < current_date then true
        else false
    end as is_calibration_overdue,
    c.next_calibration_date - current_date as days_until_calibration,

    -- 人员
    c.calibrator,
    c.reviewer,

    -- 证书
    c.certificate_no,

    -- 审计字段
    c.create_date

from calibration c
left join equipment e on c.equipment_id = e.equipment_id
left join workshop w on e.workshop_id = w.workshop_id
