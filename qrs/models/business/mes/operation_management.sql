{{
    config(
        materialized='view',
        tags=['mes', 'production', 'pqr']
    )
}}

/*
 * 工序管理业务模型
 * 数据来源: MES系统
 * 业务描述: 整合工单工序执行信息，关联工序定义和设备
 */

with work_order_operation as (
    select * from {{ ref('mes_work_order_operation') }}
),

operation as (
    select * from {{ ref('mes_operation') }}
),

work_order as (
    select * from {{ ref('mes_work_order') }}
),

equipment as (
    select * from {{ ref('mes_equipment') }}
),

personnel as (
    select * from {{ ref('mes_personnel') }}
)

select
    -- 工序执行主键
    woo.woo_id as work_order_operation_id,
    
    -- 关联工单
    woo.wo_number as work_order_number,
    wo.batch_number,
    wo.product_id,
    
    -- 工序信息
    woo.operation_id,
    op.operation_code,
    op.operation_name,
    op.operation_type,
    woo.sequence as operation_sequence,
    
    -- 标准工时
    op.standard_duration,
    op.duration_unit,
    
    -- 计划时间
    woo.planned_start,
    woo.planned_end,
    
    -- 实际时间
    woo.actual_start,
    woo.actual_end,
    
    -- 工序状态
    woo.status as operation_status,
    
    -- 设备信息
    woo.equipment_id,
    eq.equipment_name,
    eq.equipment_type,
    
    -- 操作员信息
    woo.operator_id,
    per.personnel_name as operator_name,
    
    -- 产量信息
    woo.yield_qty as yield_quantity,
    woo.defect_qty as defect_quantity,
    
    -- 良品率计算
    case 
        when woo.yield_qty > 0 then round((cast(woo.yield_qty as decimal) - woo.defect_qty) / woo.yield_qty * 100, 2)
        else 0
    end as yield_rate_percent,
    
    -- 审计字段
    woo.create_date

from work_order_operation woo
left join operation op on woo.operation_id = op.operation_id
left join work_order wo on woo.wo_number = wo.wo_number
left join equipment eq on woo.equipment_id = eq.equipment_id
left join personnel per on woo.operator_id = per.personnel_id

