{{
    config(
        materialized='view',
        tags=['intermediate', 'production', 'genealogy', 'quality', 'pqr']
    )
}}

/*
    模型: int_production__batch_genealogy
    描述: PQR 批次谱系/批次质量概览（以工单/批次为粒度，聚合偏差、检验与物料消耗）
    依赖: current_* 快照当前态视图
*/

with work_orders as (
    select
        work_order_number,
        product_id,
        batch_number,
        planned_quantity,
        actual_quantity,
        unit,
        work_order_status,
        planned_start_date,
        planned_end_date,
        actual_start_date,
        actual_end_date,
        workshop_id
    from {{ ref('current_work_orders') }}
),

deviations as (
    select
        deviation_id,
        batch_number,
        deviation_type
    from {{ ref('current_deviations') }}
),

samples as (
    select
        sample_id,
        batch_number
    from {{ ref('current_samples') }}
),

inspection_results as (
    select
        result_id,
        sample_id,
        result_status
    from {{ ref('current_inspection_results') }}
),

material_consumption as (
    select
        consumption_id,
        work_order_number,
        material_id,
        planned_quantity,
        actual_quantity
    from {{ ref('current_material_consumption') }}
),

batch_deviations as (
    select
        batch_number,
        count(*) as deviation_count,
        sum(
            case
                when deviation_type in ('Critical', '严重', '重大') then 1
                else 0
            end
        ) as critical_deviation_count
    from deviations
    where batch_number is not null
    group by batch_number
),

batch_inspections as (
    select
        s.batch_number,
        count(*) as total_tests,
        sum(
            case
                when ir.result_status in ('Fail', '不合格', '失败') then 1
                else 0
            end
        ) as failed_tests
    from samples s
    inner join inspection_results ir
        on s.sample_id = ir.sample_id
    where s.batch_number is not null
    group by s.batch_number
),

work_order_materials as (
    select
        work_order_number,
        count(*) as material_consumption_records,
        count(distinct material_id) as distinct_materials,
        sum(planned_quantity) as total_material_planned_qty,
        sum(actual_quantity) as total_material_actual_qty
    from material_consumption
    where work_order_number is not null
    group by work_order_number
),

final as (
    select
        wo.work_order_number,
        wo.batch_number,
        wo.product_id,
        cast(coalesce(wo.actual_end_date, wo.planned_end_date) as date) as manufacture_date,

        coalesce(bd.deviation_count, 0) as count_deviations,
        coalesce(bi.failed_tests, 0) as count_oos,
        coalesce(bi.total_tests, 0) as total_tests,
        coalesce(bi.failed_tests, 0) as failed_tests,

        coalesce(wm.material_consumption_records, 0) as material_consumption_records,
        coalesce(wm.distinct_materials, 0) as distinct_materials,
        coalesce(wm.total_material_planned_qty, 0) as total_material_planned_qty,
        coalesce(wm.total_material_actual_qty, 0) as total_material_actual_qty,

        case
            when coalesce(bd.critical_deviation_count, 0) > 0 then 'Critical Issues'
            when coalesce(bi.failed_tests, 0) > 0 then 'OOS Observed'
            else 'Right First Time'
        end as compliance_status

    from work_orders wo
    left join batch_deviations bd
        on wo.batch_number = bd.batch_number
    left join batch_inspections bi
        on wo.batch_number = bi.batch_number
    left join work_order_materials wm
        on wo.work_order_number = wm.work_order_number
)

select * from final
