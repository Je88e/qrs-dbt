{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='risk_level_code',
        merge_exclude_columns=['snowflake_id'],
        on_schema_change='append_new_columns',
        tags=['staging', 'qms']
    )
}}

with source_data as (
    select * from {{ source('qms_raw', 'qms_risk_levels') }}
),

final as (
    select
        {{ generate_snowflake_id() }}::text as snowflake_id,
        nullif(trim(risk_level_code::text), '') as risk_level_code,
        nullif(trim(risk_level_name::text), '') as risk_level_name,
        nullif(trim(description::text), '') as risk_level_description,
        sort_order::integer as sort_order,
        is_active::boolean as is_active,
        nullif(trim(source_system::text), '') as source_system,
        create_date::date as create_date,
        update_date::date as update_date,
        CAST(_airbyte_extracted_at AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at
    from source_data
)

select * from final
