{{
    config(
        materialized='view',
        tags=["business_model", "pqr", "scope"]
    )
}}

with batch_summary as (
    select * from {{ ref('fct_pqr_batch_summary') }}
),

final as (
    select
        review_scope_id,
        version_no,
        product_id,
        product_variant_id,
        count(distinct batch_number) as batch_count,
        count(distinct workshop_id) as workshop_count,
        sum(planned_quantity) as total_planned_quantity,
        sum(actual_quantity) as total_actual_quantity,
        case
            when sum(planned_quantity) > 0
            then round(cast(sum(actual_quantity) as decimal) / sum(planned_quantity) * 100, 2)
            else null
        end as completion_rate_percent,
        min(batch_start_at) as first_batch_start_at,
        max(batch_end_at) as last_batch_end_at
    from batch_summary
    group by 1, 2, 3, 4
)

select * from final
