{{
    config(
        materialized='view',
        tags=["business_model", "pqr", "scope"]
    )
}}

with scope_workshop as (
    select * from {{ ref('stg_pqr_scope_workshops') }}
),

final as (
    select
        review_scope_id,
        version_no,
        workshop_id,
        max(loaded_at) as loaded_at
    from scope_workshop
    group by 1, 2, 3
)

select * from final
