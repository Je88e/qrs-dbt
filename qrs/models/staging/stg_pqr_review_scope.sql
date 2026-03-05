{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='review_scope_id',
        merge_exclude_columns=['snowflake_id'],
        on_schema_change='append_new_columns',
        tags=["staging", "pqr", "scope"]
    )
}}

with source_data as (
    select * from {{ source('pqr_raw','seed_pqr_review_scope') }}
),

final as (
    select
        {{ generate_snowflake_id() }}::text as snowflake_id,
        review_scope_id::text as review_scope_id,
        product_id::text as product_id,
        product_variant_id::text as product_variant_id,
        cast(period_start_date as date) as period_start_date,
        cast(period_end_date as date) as period_end_date,
        version_no::text as version_no,
        cast(is_frozen as boolean) as is_frozen,
        cast(frozen_at as timestamptz) as frozen_at,
        cast(generated_at as timestamptz) as generated_at,
        cast(source_loaded_at_max as timestamptz) as source_loaded_at_max,
        cast(loaded_at as timestamptz) as loaded_at
    from source_data
)

select * from final
{% if is_incremental() %}
where loaded_at > (
    select coalesce(max(loaded_at), CAST('1900-01-01 00:00:00.000 +0800' AS timestamptz))
           - interval '{{ var("incremental_lookback_minutes", 5) }} minutes'
    from {{ this }}
)
{% endif %}
