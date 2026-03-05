with variant as (
    select * from {{ ref('dim_product_variant') }}
)

select
    product_variant_id,
    product_id,
    variant_code,
    variant_name,
    effective_start_date,
    is_active
from variant
where is_active
  and (
        product_id is null
     or variant_code is null
     or variant_name is null
     or effective_start_date is null
  )
