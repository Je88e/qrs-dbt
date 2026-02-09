{{
    config(
        materialized='view',
        tags=['lims', 'water', 'quality', 'pqr']
    )
}}

/*
    Model: fct_water_quality
    Description: 工艺用水质量监控 - 从水质检测数据中提供合规分析
*/

with water_quality as (
    select * from {{ ref('stg_water_quality') }}
),

analyst as (
    select * from {{ ref('stg_analyst') }}
),

equipment as (
    select * from {{ ref('stg_equipment') }}
)

select
    -- 主键
    wq.test_id,

    -- 监测点信息
    wq.monitoring_point_id,
    wq.monitoring_point_name,
    wq.water_type,

    -- 检测参数
    wq.parameter_name,
    wq.test_value,
    wq.test_unit,
    wq.limit_min,
    wq.limit_max,

    -- 合规性判断
    wq.result_status,
    case
        when wq.limit_min is not null and wq.limit_max is not null
        then wq.test_value between wq.limit_min and wq.limit_max
        when wq.limit_max is not null
        then wq.test_value <= wq.limit_max
        when wq.limit_min is not null
        then wq.test_value >= wq.limit_min
        else true
    end as is_within_limit,

    -- 时间信息
    wq.test_date,
    extract(year from wq.test_date) as test_year,
    extract(month from wq.test_date) as test_month,

    -- 分析员信息
    wq.analyst_id,
    a.analyst_name,
    a.qualification as analyst_qualification,

    -- 设备信息
    wq.equipment_id,
    e.equipment_code,
    e.equipment_name,

    -- 批次关联
    wq.batch_number,

    -- 审计字段
    wq.create_date

from water_quality wq
left join analyst a on wq.analyst_id = a.analyst_id
left join equipment e on wq.equipment_id = e.equipment_id
