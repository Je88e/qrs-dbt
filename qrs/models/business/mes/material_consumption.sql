{{
    config(
        materialized='view',
        tags=['mes', 'production', 'material', 'pqr']
    )
}}

/*
 * 物料消耗业务模型
 * 数据来源: MES系统
 * 业务描述: 记录生产过程中的物料消耗，用于物料平衡分析
 */

with material_consumption as (
    select * from {{ ref('mes_material_consumption') }}
),

work_order as (
    select * from {{ ref('mes_work_order') }}
),

operation as (
    select * from {{ ref('mes_operation') }}
),

material as (
    select * from {{ ref('erp_material_master') }}
),

personnel as (
    select * from {{ ref('mes_personnel') }}
)

select
    -- 消耗主键
    mc.consumption_id,
    
    -- 关联工单
    mc.wo_number as work_order_number,
    wo.product_id,
    wo.batch_number as wo_batch_number,
    
    -- 工序信息
    mc.operation_id,
    op.operation_name,
    
    -- 物料信息
    mc.material_id,
    m.material_name,
    m.material_type,
    mc.batch_number as material_batch_number,
    
    -- 消耗数量
    mc.planned_qty as planned_quantity,
    mc.actual_qty as actual_quantity,
    mc.unit,
    
    -- 差异分析
    mc.actual_qty - mc.planned_qty as variance_quantity,
    case 
        when mc.planned_qty > 0 then round((cast(mc.actual_qty as decimal) - mc.planned_qty) / mc.planned_qty * 100, 2)
        else 0
    end as variance_percent,
    mc.variance_reason,
    
    -- 消耗时间
    mc.consumption_date,
    
    -- 操作员信息
    mc.operator_id,
    per.personnel_name as operator_name,
    
    -- 审计字段
    mc.create_date

from material_consumption mc
left join work_order wo on mc.wo_number = wo.wo_number
left join operation op on mc.operation_id = op.operation_id
left join material m on mc.material_id = m.material_id
left join personnel per on mc.operator_id = per.personnel_id

