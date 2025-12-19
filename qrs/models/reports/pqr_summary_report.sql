{{
    config(
        materialized='table',
        tags=['report', 'pqr', 'summary']
    )
}}

/*
 * PQR汇总报告模型
 * 整合各业务模块的关键指标
 * 数据来源: 各系统业务模型
 * 更新日期: 2024-01-20
 */

-- 物料统计 (来自Staging层)
with material_stats as (
    select
        count(*) as total_materials,
        count(case when approval_status = '已审批' then 1 end) as approved_materials,
        count(distinct supplier_id) as total_suppliers
    from {{ ref('stg_material_master') }}
),

-- 供应商统计 (来自Staging层)
supplier_stats as (
    select
        count(*) as total_suppliers,
        count(case when qualification_status = '合格' then 1 end) as qualified_suppliers,
        avg(cast(audit_score as decimal)) as avg_audit_score
    from {{ ref('stg_supplier_master') }}
),

-- 供应商审计统计 (来自Business层)
supplier_audit_stats as (
    select
        count(*) as total_audits,
        count(case when audit_result = '合格' then 1 end) as passed_audits,
        avg(audit_score) as avg_audit_score
    from {{ ref('fct_supplier_audits') }}
),

-- 生产统计 (来自Business层)
production_stats as (
    select
        count(*) as total_work_orders,
        count(case when work_order_status = '已完成' then 1 end) as completed_orders,
        sum(planned_quantity) as total_planned_qty,
        sum(actual_quantity) as total_actual_qty
    from {{ ref('fct_work_orders') }}
),

-- 生产效率统计 (来自Intermediate层)
production_efficiency_stats as (
    select
        sum(on_time_orders) as on_time_orders,
        avg(avg_yield_rate) as avg_yield_rate,
        avg(on_time_completion_rate) as avg_on_time_rate
    from {{ ref('int_production__efficiency_metrics') }}
),

-- 质量检验统计 (来自Business层)
quality_stats as (
    select
        count(*) as total_inspection_requests,
        count(case when request_status = '已完成' then 1 end) as completed_inspections
    from {{ ref('fct_inspection_requests') }}
),

-- 质量分析统计 (来自Intermediate层)
quality_analytics_stats as (
    select
        sum(on_time_requests) as on_time_inspections,
        avg(avg_processing_days) as avg_inspection_days,
        avg(on_time_rate) as avg_on_time_rate
    from {{ ref('int_quality__inspection_metrics') }}
),

-- 偏差统计 (来自Business层)
deviation_stats as (
    select
        count(*) as total_deviations,
        count(case when deviation_status = '已关闭' then 1 end) as closed_deviations,
        avg(closure_days) as avg_closure_days
    from {{ ref('fct_deviations') }}
),

-- CAPA统计 (来自Business层)
capa_stats as (
    select
        count(*) as total_capas,
        count(case when capa_status = '已完成' or capa_status = '已关闭' then 1 end) as completed_capas,
        count(case when effectiveness_check = '有效' then 1 end) as effective_capas
    from {{ ref('fct_capas') }}
),

final as (
    select
        -- 物料统计
        m.total_materials,
        m.approved_materials,
        case
            when m.total_materials > 0 then
                round(m.approved_materials * 100.0 / m.total_materials, 2)
            else 0
        end as material_approval_rate,

        -- 供应商统计
        s.total_suppliers,
        s.qualified_suppliers,
        case
            when s.total_suppliers > 0 then
                round(s.qualified_suppliers * 100.0 / s.total_suppliers, 2)
            else 0
        end as supplier_qualification_rate,
        round(cast(coalesce(sa.avg_audit_score, 0) as numeric), 2) as avg_supplier_audit_score,

        -- 生产统计
        p.total_work_orders,
        p.completed_orders,
        case
            when p.total_work_orders > 0 then
                round(p.completed_orders * 100.0 / p.total_work_orders, 2)
            else 0
        end as production_completion_rate,
        round(cast(coalesce(pe.avg_on_time_rate, 0) as numeric), 2) as production_on_time_rate,
        round(cast(coalesce(pe.avg_yield_rate, 0) as numeric), 2) as avg_production_yield_rate,

        -- 质量检验统计
        q.total_inspection_requests,
        q.completed_inspections,
        case
            when q.total_inspection_requests > 0 then
                round(q.completed_inspections * 100.0 / q.total_inspection_requests, 2)
            else 0
        end as inspection_completion_rate,
        round(cast(coalesce(qa.avg_on_time_rate, 0) as numeric), 2) as inspection_on_time_rate,
        round(cast(coalesce(qa.avg_inspection_days, 0) as numeric), 1) as avg_inspection_processing_days,

        -- 偏差统计
        d.total_deviations,
        d.closed_deviations,
        case
            when d.total_deviations > 0 then
                round(d.closed_deviations * 100.0 / d.total_deviations, 2)
            else 0
        end as deviation_closure_rate,
        round(cast(coalesce(d.avg_closure_days, 0) as numeric), 1) as avg_deviation_closure_days,

        -- CAPA统计
        c.total_capas,
        c.completed_capas,
        case
            when c.total_capas > 0 then
                round(c.completed_capas * 100.0 / c.total_capas, 2)
            else 0
        end as capa_completion_rate,
        case
            when c.completed_capas > 0 then
                round(c.effective_capas * 100.0 / c.completed_capas, 2)
            else 0
        end as capa_effectiveness_rate,

        -- 报告生成时间
        current_timestamp as report_generated_at

    from material_stats m
    cross join supplier_stats s
    cross join supplier_audit_stats sa
    cross join production_stats p
    cross join production_efficiency_stats pe
    cross join quality_stats q
    cross join quality_analytics_stats qa
    cross join deviation_stats d
    cross join capa_stats c
)

select * from final