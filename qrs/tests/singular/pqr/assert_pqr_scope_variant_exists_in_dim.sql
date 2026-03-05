with scope as (
    select
        review_scope_id,
        version_no,
        product_variant_id
    from {{ ref('dim_pqr_review_scope') }}
),

variant as (
    select product_variant_id from {{ ref('dim_product_variant') }}
)

select
    s.review_scope_id,
    s.version_no,
    s.product_variant_id
from scope s
left join variant v on s.product_variant_id = v.product_variant_id
where v.product_variant_id is null
