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
    select * from {{ source('pqr_raw','seed_pqr_scope_workshops') }}
),

final as (
    select
        {{ generate_snowflake_id() }}::text as snowflake_id,
        review_scope_id::text as review_scope_id,
        workshop_id::text as workshop_id,
        version_no::text as version_no,
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
