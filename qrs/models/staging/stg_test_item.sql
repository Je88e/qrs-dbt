{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['staging', 'lims', 'master_data']
    )
}}

/*
    Model: stg_test_item
    Description: LIMS检验项目主数据原始数据清洗层 - Staging层
    Source: LIMS系统检验项目定义表
    Grain: 每行代表一个检验项目
*/

with source_data as (
    select * from {{ source('lims_raw', 'lims_test_item') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        test_item_id,
        item_code,
        item_name,
        test_method,
        standard_id,
        min_value,
        max_value,
        unit,
        required_equipment,
        test_duration,
        test_duration_unit,
        status as item_status,
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