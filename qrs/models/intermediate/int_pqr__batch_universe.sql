{{
    config(
        materialized='view',
        tags=["intermediate", "pqr", "scope"]
    )
}}

with review_scope as (
    select * from {{ ref('stg_pqr_review_scope') }}
),

scope_workshop as (
    select * from {{ ref('stg_pqr_scope_workshops') }}
),

work_orders as (
    select * from {{ ref('fct_work_orders') }}
),

scoped_work_orders as (
    select
        s.review_scope_id,
        s.version_no,
        wo.batch_number,
        wo.product_id,
        s.product_variant_id,
        wo.workshop_id,
        coalesce(wo.actual_start_date, wo.planned_start_date)::timestamptz as batch_start_at,
        coalesce(wo.actual_end_date, wo.planned_end_date)::timestamptz as batch_end_at
    from review_scope s
    inner join scope_workshop sw
        on s.review_scope_id = sw.review_scope_id
       and s.version_no = sw.version_no
    inner join work_orders wo
        on wo.product_id = s.product_id
       and wo.workshop_id = sw.workshop_id
       and coalesce(wo.actual_start_date, wo.planned_start_date)::date between s.period_start_date and s.period_end_date
),

final as (
    select
        review_scope_id,
        version_no,
        batch_number,
        product_id,
        product_variant_id,
        workshop_id,
        min(batch_start_at) as batch_start_at,
        max(batch_end_at) as batch_end_at
    from scoped_work_orders
    group by 1, 2, 3, 4, 5, 6
)

select * from final
