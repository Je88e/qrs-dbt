{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['staging', 'lims', 'master_data']
    )
}}

/*
    Model: stg_analyst
    Description: LIMS分析员主数据原始数据清洗层 - Staging层
    Source: LIMS系统分析员主数据表
    Grain: 每行代表一个分析员
*/

with source_data as (
    select * from {{ source('lims_raw', 'lims_analyst') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        analyst_id,
        analyst_code,
        analyst_name,
        department,
        qualification,
        certification_date,
        certification_expiry,
        status as analyst_status,
        create_date,
        update_date,
        _airbyte_extracted_at as loaded_at
    from source_data
)

select * from final
{% if is_incremental() %}
where _loaded_at > (
    select coalesce(max(_loaded_at), '1900-01-01'::timestamp)
           - interval '{{ var("incremental_lookback_minutes", 5) }} minutes'
    from {{ this }}
)
{% endif %}