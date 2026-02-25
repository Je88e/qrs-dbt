{{
    config(
        materialized='view',
        tags=['intermediate', 'production', 'operation', 'window', 'pqr']
    )
}}

/*
    模型: int_production__operation_windows
    描述: 工序窗口中间模型 - 以工单工序执行记录为粒度，形成工序 start/end 窗口用于对齐 SCADA 采集点
*/

with work_order_operations as (
    select
        work_order_operation_id,
        work_order_number,
        operation_id,
        operation_sequence,
        planned_start::timestamptz as planned_start_at,
        planned_end::timestamptz as planned_end_at,
        actual_start::timestamptz as actual_start_at,
        actual_end::timestamptz as actual_end_at,
        operation_status,
        equipment_id,
        operator_id,
        yield_quantity,
        defect_quantity,
        create_date,
        update_date,
        loaded_at as source_loaded_at
    from {{ ref('stg_work_order_operation') }}
),

work_orders as (
    select
        work_order_number,
        product_id,
        batch_number
    from {{ ref('stg_work_order') }}
),

operations as (
    select
        operation_id,
        operation_code,
        operation_name,
        operation_type
    from {{ ref('stg_operation') }}
),

final as (
    select
        woo.work_order_operation_id,
        woo.work_order_number,
        wo.batch_number,
        wo.product_id,
        woo.operation_id,
        op.operation_code,
        op.operation_name,
        op.operation_type,
        woo.operation_sequence,
        woo.operation_status,
        woo.equipment_id,
        woo.operator_id,
        woo.yield_quantity,
        woo.defect_quantity,
        case
            when woo.actual_start_at is not null or woo.actual_end_at is not null then 'actual'
            when woo.planned_start_at is not null or woo.planned_end_at is not null then 'planned'
            else 'unknown'
        end as window_source,
        coalesce(woo.actual_start_at, woo.planned_start_at) as window_start_at,
        coalesce(woo.actual_end_at, woo.planned_end_at) as window_end_at,
        woo.source_loaded_at,
        woo.create_date,
        woo.update_date
    from work_order_operations woo
    left join work_orders wo
        on woo.work_order_number = wo.work_order_number
    left join operations op
        on woo.operation_id = op.operation_id
)

select * from final
