{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['staging', 'lims', 'master_data']
    )
}}

/*
    Model: stg_quality_standard
    Description: LIMS质量标准主数据原始数据清洗层 - Staging层
    Source: LIMS系统质量标准主表
    Grain: 每行代表一个质量标准
*/

with source_data as (
    select * from {{ source('lims_raw', 'lims_quality_standard') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        standard_id,
        standard_code,
        standard_name,
        material_type,
        version as standard_version,
        effective_date,
        expiry_date,
        status as standard_status,
        creator,
        approver,
        approval_date,
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