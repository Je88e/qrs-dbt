{{
    config(
        materialized='table',
        tags=['mes', 'production', 'efficiency', 'analytics', 'pqr']
    )
}}

/*
 * 生产效率分析模型
 * 数据来源: MES系统业务模型
 * 业务描述: 基于工单数据分析生产效率指标，用于PQR报告
 * 模型类型: 聚合分析模型
 */

with work_order_base as (
    select
        work_order_number,
        workshop_id,
        workshop_name,
        product_id,
        work_order_status,
        planned_quantity,
        actual_quantity,
        planned_start_date,
        planned_end_date,
        actual_start_date,
        actual_end_date,
        completion_rate_percent
    from {{ ref('work_order') }}
),

work_order_enriched as (
    select
        work_order_number,
        workshop_id,
        workshop_name,
        product_id,
        work_order_status,
        planned_quantity,
        actual_quantity,
        planned_start_date,
        planned_end_date,
        actual_start_date,
        actual_end_date,
        completion_rate_percent,
        -- 计算收率
        case 
            when planned_quantity > 0 then 
                round(cast(actual_quantity as decimal) * 100.0 / planned_quantity, 2)
            else null 
        end as yield_rate,
        -- 计算实际工期（天）
        case
            when actual_end_date is not null and actual_start_date is not null then
                {{ date_diff_days('actual_end_date', 'actual_start_date') }}
            else null
        end as actual_duration_days,
        -- 是否按时完成
        case 
            when work_order_status = '已完成' and actual_end_date <= planned_end_date then true
            when work_order_status = '已完成' and actual_end_date > planned_end_date then false
            else null
        end as is_on_time
    from work_order_base
),

production_summary as (
    select
        workshop_id,
        workshop_name,
        product_id,
        work_order_status,
        count(*) as total_orders,
        count(case when is_on_time = true then 1 end) as on_time_orders,
        avg(yield_rate) as avg_yield_rate,
        avg(actual_duration_days) as avg_duration_days,
        sum(planned_quantity) as total_planned_qty,
        sum(actual_quantity) as total_actual_qty
    from work_order_enriched
    group by workshop_id, workshop_name, product_id, work_order_status
),

final as (
    select
        workshop_id,
        workshop_name,
        product_id,
        work_order_status,
        total_orders,
        on_time_orders,
        -- 按时完成率
        case 
            when total_orders > 0 then 
                round(on_time_orders * 100.0 / total_orders, 2)
            else 0 
        end as on_time_completion_rate,
        -- 平均收率
        round(avg_yield_rate, 2) as avg_yield_rate,
        -- 平均工期
        round(avg_duration_days, 1) as avg_duration_days,
        -- 总体收率
        case 
            when total_planned_qty > 0 then 
                round(total_actual_qty * 100.0 / total_planned_qty, 2)
            else 0 
        end as overall_yield_rate,
        total_planned_qty,
        total_actual_qty
    from production_summary
)

select * from final

