{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['staging', 'lims', 'quality']
    )
}}

/*
    Model: stg_sample
    Description: LIMS样品主数据原始数据清洗层 - Staging层
    Source: LIMS系统样品主数据表
    Grain: 每行代表一个样品
*/

with source_data as (
    select * from {{ source('lims_raw', 'lims_sample') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        sample_id,
        sample_code,
        sample_type,
        sample_qty as sample_quantity,
        sample_unit,
        material_id, 
        batch_number,
        sample_date,
        sampler,
        storage_condition,
        location as storage_location,
        expiry_date,
        sample_status,
        create_date,
        update_date,
        CAST(_airbyte_extracted_at AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at
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