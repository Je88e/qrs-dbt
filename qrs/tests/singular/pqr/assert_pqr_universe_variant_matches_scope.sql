with universe as (
    select
        review_scope_id,
        version_no,
        product_variant_id
    from {{ ref('int_pqr__batch_universe') }}
),

scope as (
    select
        review_scope_id,
        version_no,
        product_variant_id as scope_product_variant_id
    from {{ ref('dim_pqr_review_scope') }}
)

select
    u.review_scope_id,
    u.version_no,
    u.product_variant_id as universe_product_variant_id,
    s.scope_product_variant_id
from universe u
inner join scope s
    on u.review_scope_id = s.review_scope_id
   and u.version_no = s.version_no
where u.product_variant_id <> s.scope_product_variant_id
