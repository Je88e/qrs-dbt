with scope as (
    select
        review_scope_id,
        version_no,
        count(distinct product_variant_id) as variant_count
    from {{ ref('dim_pqr_review_scope') }}
    group by 1, 2
)

select *
from scope
where variant_count <> 1
