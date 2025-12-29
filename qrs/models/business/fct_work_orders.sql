{{
    config(
        materialized='view',
        tags=['mes', 'production', 'pqr']
    )
}}

/*
    Model: fct_work_orders
    Description: 生产工单事实表 - 提供生产工单的完整信息，关联车间和产线
*/

-- 1. Import CTEs: 显式声明所有依赖
with work_order as (
    select * from {{ ref('stg_work_order') }}
),

workshop as (
    select * from {{ ref('stg_workshop') }}
),

-- 2. Logic CTEs: 业务逻辑处理
final as (
    select
        -- 工单主键
        wo.work_order_number,

        -- 产品信息
        wo.product_id,
        wo.batch_number,

        -- 数量信息
        wo.planned_quantity,
        wo.actual_quantity,
        wo.unit,

        -- 工单状态
        wo.work_order_status,

        -- 计划时间
        wo.planned_start_date,
        wo.planned_end_date,

        -- 实际时间
        wo.actual_start_date,
        wo.actual_end_date,

        -- 车间信息
        wo.workshop_id,
        ws.workshop_name,
        ws.workshop_type,
        ws.workshop_manager,
        ws.workshop_status, 

        -- 完成率计算
        case
            when wo.planned_quantity > 0 then
                round(cast(wo.actual_quantity as decimal) / wo.planned_quantity * 100, 2)
            else 0
        end as completion_rate_percent,

        -- 审计字段
        wo.create_by,
        wo.create_date

    from work_order wo
    left join workshop ws on wo.workshop_id = ws.workshop_id
)

-- 3. Output: 必须选择 Final CTE
select * from final

