{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='root_cause_category_code',
        merge_exclude_columns=['snowflake_id'],
        on_schema_change='append_new_columns',
        tags=['staging', 'qms']
    )
}}

with source_data as (
    select * from {{ source('qms_raw', 'qms_root_cause_categories') }}
),

final as (
    select
        {{ generate_snowflake_id() }}::text as snowflake_id,
        nullif(trim(root_cause_category_code::text), '') as root_cause_category_code,
        nullif(trim(root_cause_category_name::text), '') as root_cause_category_name,
        nullif(trim(description::text), '') as root_cause_category_description,
        sort_order::integer as sort_order,
        is_active::boolean as is_active,
        nullif(trim(source_system::text), '') as source_system,
        create_date::date as create_date,
        update_date::date as update_date,
        CAST(_airbyte_extracted_at AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at
    from source_data
)

select * from final
