with universe as (
    select
        version_no,
        batch_number,
        count(distinct product_variant_id) as variant_count
    from {{ ref('int_pqr__batch_universe') }}
    group by 1, 2
)

select *
from universe
where variant_count > 1
