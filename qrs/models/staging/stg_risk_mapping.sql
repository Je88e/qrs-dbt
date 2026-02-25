{{
    config(
        
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='mapping_id',
        merge_exclude_columns=['snowflake_id'],
        on_schema_change='append_new_columns',
        tags=['staging', 'qms']
    )
}}

with source_data as (
    select * from {{ source('qms_raw', 'qms_risk_mapping') }}
),

final as (
    select
        {{ generate_snowflake_id() }}::text as snowflake_id,
        nullif(trim(mapping_id::text), '') as mapping_id,
        nullif(trim(source_system::text), '') as source_system,
        nullif(trim(event_type::text), '') as event_type,
        nullif(trim(raw_value::text), '') as raw_value,
        nullif(trim(risk_level_code::text), '') as risk_level_code,
        priority::integer as priority,
        is_active::boolean as is_active,
        create_date::date as create_date,
        update_date::date as update_date,
        CAST(_airbyte_extracted_at AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at
    from source_data
)

select * from final
