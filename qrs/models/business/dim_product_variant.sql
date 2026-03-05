{{
    config(
        materialized='view',
        tags=["business_model", "pqr", "variant"]
    )
}}

with variant as (
    select * from {{ ref('stg_product_variant_map') }}
),

final as (
    select
        product_variant_id,
        product_id,
        variant_code,
        variant_name,
        packaging,
        specification,
        effective_start_date,
        effective_end_date,
        is_active,
        case
            when is_active
             and (effective_start_date is null or effective_start_date <= current_date)
             and (effective_end_date is null or effective_end_date >= current_date)
            then true
            else false
        end as is_current,
        loaded_at
    from variant
)

select * from final
