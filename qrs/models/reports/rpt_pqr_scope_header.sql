{{
    config(
        materialized='view',
        tags=['report', 'pqr']
    )
}}

with scope as (
    select * from {{ ref('dim_pqr_review_scope') }}
),

scope_summary as (
    select * from {{ ref('fct_pqr_review_scope_summary') }}
),

final as (
    select
        s.review_scope_id,
        s.version_no,
        s.product_id,
        s.product_variant_id,
        s.period_start_date,
        s.period_end_date,
        s.is_frozen,
        s.frozen_at,
        s.generated_at,
        s.source_loaded_at_max,
        s.workshop_count as workshop_count_dim,
        s.workshop_list,
        ss.batch_count,
        ss.workshop_count as workshop_count_universe,
        ss.total_planned_quantity,
        ss.total_actual_quantity,
        ss.completion_rate_percent,
        ss.first_batch_start_at,
        ss.last_batch_end_at
    from scope s
    left join scope_summary ss
        on s.review_scope_id = ss.review_scope_id
       and s.version_no = ss.version_no
)

select * from final
