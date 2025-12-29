{{
    config(
        materialized='view',
        tags=['scada', 'production', 'tracking', 'pqr']
    )
}}

/*
    Model: fct_batch_tracking
    Description: 提供生产批次的全程追踪信息
*/

with batch_tracking as (
    select * from {{ ref('stg_batch_tracking') }}
),

work_order as (
    select * from {{ ref('stg_work_order') }}
),

operation as (
    select * from {{ ref('stg_operation') }}
),

equipment as (
    select * from {{ ref('stg_equipment') }}
),

personnel as (
    select * from {{ ref('stg_personnel') }}
)

select
    -- 追踪主键
    bt.tracking_id,
    
    -- 批次信息
    bt.batch_number,
    bt.work_order_number,
    bt.product_id,
    
    -- 工序信息
    bt.operation_id,
    op.operation_name,
    op.operation_type,
    
    -- 设备信息
    bt.equipment_id,
    eq.equipment_code,
    eq.equipment_name,
    
    -- 时间信息
    bt.start_time,
    bt.end_time,
    
    -- 执行时长（分钟）
    case
        when bt.end_time is not null and bt.start_time is not null
        then {{ timestamp_diff_minutes('bt.end_time', 'bt.start_time') }}
        else null
    end as duration_minutes,
    
    -- 状态
    bt.tracking_status,
    
    -- 操作员
    bt.operator_id,
    per.personnel_name as operator_name,
    
    -- 产量信息
    bt.yield_quantity,
    bt.unit,
    bt.quality_status,
    
    -- 备注
    bt.remark,
    
    -- 审计字段
    bt.create_date

from batch_tracking bt
left join work_order wo on bt.work_order_number = wo.work_order_number
left join operation op on bt.operation_id = op.operation_id
left join equipment eq on bt.equipment_id = eq.equipment_id
left join personnel per on bt.operator_id = per.personnel_id

