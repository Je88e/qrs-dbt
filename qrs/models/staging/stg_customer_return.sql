{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='limit_id',
        merge_exclude_columns=['snowflake_id'],
        on_schema_change='append_new_columns',
        tags=['staging', 'erp', 'returns']
    )
}}

/*
    Model: stg_customer_return
    Description: PQR成品退货台账 - 种子数据清洗与类型标准化（Staging层）
    Source: erp_customer_returns (CSV)
    Grain: 每行代表一条成品退货记录
*/

with source_data as (
    select * from {{ source('erp_raw','erp_customer_returns') }}
),

final as (
    select
        {{ generate_snowflake_id() }}::text as snowflake_id,
        nullif(trim(return_id::text), '') as return_id,
        nullif(trim(return_code::text), '') as return_code,
        nullif(trim(product_id::text), '') as product_id,
        nullif(trim(batch_number::text), '') as batch_number,
        nullif(trim(customer_name::text), '') as customer_name,
        nullif(trim(return_date::text), '')::date as return_date,
        nullif(trim(return_quantity::text), '')::numeric as return_quantity,
        nullif(trim(unit::text), '') as unit,
        nullif(trim(return_reason::text), '') as return_reason,
        nullif(trim(return_type::text), '') as return_type,
        nullif(trim(return_status::text), '') as return_status,
        nullif(trim(create_date::text), '')::timestamp as create_date,
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

