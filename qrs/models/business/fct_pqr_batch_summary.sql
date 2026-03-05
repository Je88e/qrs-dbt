{{
    config(
        materialized='view',
        tags=["business_model", "pqr", "scope"]
    )
}}

with batch_universe as (
    select * from {{ ref('int_pqr__batch_universe') }}
),

work_orders as (
    select * from {{ ref('fct_work_orders') }}
),

joined as (
    select
        u.review_scope_id,
        u.version_no,
        u.batch_number,
        u.product_id,
        u.product_variant_id,
        u.workshop_id,
        u.batch_start_at,
        u.batch_end_at,
        wo.work_order_number,
        wo.planned_quantity,
        wo.actual_quantity,
        wo.unit,
        wo.work_order_status
    from batch_universe u
    left join work_orders wo
        on u.batch_number = wo.batch_number
       and u.product_id = wo.product_id
       and u.workshop_id = wo.workshop_id
),

final as (
    select
        review_scope_id,
        version_no,
        batch_number,
        product_id,
        product_variant_id,
        workshop_id,
        batch_start_at,
        batch_end_at,
        count(distinct work_order_number) as work_order_count,
        sum(planned_quantity) as planned_quantity,
        sum(actual_quantity) as actual_quantity,
        max(unit) as unit,
        sum(case when work_order_status = '已完成' then 1 else 0 end) as completed_work_order_count,
        case
            when sum(planned_quantity) > 0
            then round(cast(sum(actual_quantity) as decimal) / sum(planned_quantity) * 100, 2)
            else null
        end as completion_rate_percent
    from joined
    group by 1, 2, 3, 4, 5, 6, 7, 8
)

select * from final
