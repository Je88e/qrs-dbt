with variant as (
    select
        product_variant_id,
        effective_start_date,
        effective_end_date
    from {{ ref('dim_product_variant') }}
)

select *
from variant
where effective_end_date is not null
  and effective_end_date < effective_start_date
