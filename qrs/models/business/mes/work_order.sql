{{
    config(
        materialized='view',
        tags=['mes', 'production', 'pqr']
    )
}}

/*
 * 生产工单业务模型
 * 数据来源: MES系统
 * 业务描述: 提供生产工单的完整信息，关联车间和产线
 */

with work_order as (
    select * from {{ ref('mes_work_order') }}
),

workshop as (
    select * from {{ ref('mes_workshop') }}
)

select
    -- 工单主键
    wo.wo_number as work_order_number,
    
    -- 产品信息
    wo.product_id,
    wo.batch_number,
    
    -- 数量信息
    wo.planned_qty as planned_quantity,
    wo.actual_qty as actual_quantity,
    wo.unit,
    
    -- 工单状态
    wo.wo_status as work_order_status,
    
    -- 计划时间
    wo.plan_start_date as planned_start_date,
    wo.plan_end_date as planned_end_date,
    
    -- 实际时间
    wo.actual_start_date,
    wo.actual_end_date,
    
    -- 车间信息
    wo.workshop_id,
    ws.workshop_name,
    ws.workshop_type,
    ws.clean_level,
    
    -- 完成率计算
    case 
        when wo.planned_qty > 0 then round(cast(wo.actual_qty as decimal) / wo.planned_qty * 100, 2)
        else 0
    end as completion_rate_percent,
    
    -- 创建信息
    wo.create_by as created_by,
    wo.create_date

from work_order wo
left join workshop ws on wo.workshop_id = ws.workshop_id

