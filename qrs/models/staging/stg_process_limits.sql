{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='limit_id',
        merge_exclude_columns=['snowflake_id'],
        on_schema_change='append_new_columns',
        tags=['staging', 'mes', 'cpp']
    )
}}

/*
    Model: stg_process_limits
    Description: PQR关键工艺参数(CPP)限度 - 种子数据清洗与类型标准化（Staging层）
    Source: mes_process_limits (CSV)
    Grain: 每行代表一个 产品+工序+参数 的限度版本记录
*/

with source_data as (
    select * from {{ source('mes_raw', 'mes_process_limits') }}
),

final as (
    select
        {{ generate_snowflake_id() }}::text as snowflake_id,
        nullif(trim(limit_id::text), '') as limit_id,
        nullif(trim(product_id::text), '') as product_id,
        nullif(trim(operation_id::text), '') as operation_id,
        nullif(trim(param_name::text), '') as param_name,
        nullif(trim(min_value::text), '')::numeric as min_value,
        nullif(trim(max_value::text), '')::numeric as max_value,
        nullif(trim(unit::text), '') as unit,
        nullif(trim(effective_start_date::text), '')::date as effective_start_date,
        nullif(trim(effective_end_date::text), '')::date as effective_end_date,
        nullif(trim(limit_version::text), '') as limit_version,
        nullif(trim(limit_status::text), '') as limit_status,
        nullif(trim(_airbyte_extracted_at::text), '')::timestamptz as loaded_at
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

