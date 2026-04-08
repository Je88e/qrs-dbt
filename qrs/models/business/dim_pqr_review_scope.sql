{{
    config(
        materialized='view',
        tags=["business_model", "pqr", "scope"]
    )
}}

with scope as (
    select * from {{ ref('stg_pqr_review_scope') }}
),

scope_workshop_agg as (
    select * from {{ ref('int_pqr__scope_workshop_agg') }}
),

final as (
    select
        s.review_scope_id,
        s.product_id,
        s.product_variant_id,
        s.period_start_date,
        s.period_end_date,
        s.version_no,
        s.scope_type,
        s.review_year,
        s.review_month,
        s.scope_reason,
        s.qa_owner,
        s.review_status,
        s.is_frozen,
        s.frozen_at,
        s.approved_at,
        s.approver,
        s.generated_at,
        s.source_loaded_at_max,
        coalesce(a.workshop_count, 0) as workshop_count,
        a.workshop_list,
        s.remark,
        s.loaded_at
    from scope s
    left join scope_workshop_agg a
        on s.review_scope_id = a.review_scope_id
       and s.version_no = a.version_no
)

select * from final
