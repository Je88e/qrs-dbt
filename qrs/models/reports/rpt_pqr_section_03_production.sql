{{
    config(
        materialized='view',
        tags=['report', 'pqr']
    )
}}

with batch_summary as (
    select * from {{ ref('fct_pqr_batch_summary') }}
),

workshops as (
    select * from {{ ref('dim_workshops') }}
),

final as (
    select
        b.review_scope_id,
        b.version_no,
        b.batch_number,
        b.product_id,
        b.product_variant_id,
        b.workshop_id,
        w.workshop_name,
        b.batch_start_at,
        b.batch_end_at,
        b.work_order_count,
        b.planned_quantity,
        b.actual_quantity,
        b.unit,
        b.completed_work_order_count,
        b.completion_rate_percent
    from batch_summary b
    left join workshops w on b.workshop_id = w.workshop_id
)

select * from final
