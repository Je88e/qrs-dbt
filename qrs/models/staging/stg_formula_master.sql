{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='formula_id',
        merge_exclude_columns=['snowflake_id'],
        on_schema_change='append_new_columns',
        tags=['staging', 'erp', 'master_data']
    )
}}

/*
    Model: stg_formula_master
    Description: ERP配方主数据原始数据清洗层 - Staging层
    Source: ERP系统配方主数据表
    Grain: 每行代表一个配方
*/

with source_data as (
    select * from {{ source('erp_raw', 'erp_formula_master') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        formula_id,
        formula_name,
        product_id,
        product_name,
        version as formula_version,
        formula_status,
        effective_date,
        expiry_date,
        batch_size,
        batch_unit,
        creator,
        approver,
        approval_date,
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