{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='recall_id',
        merge_exclude_columns=['snowflake_id'],
        on_schema_change='append_new_columns',
        tags=['staging', 'pv', 'safety']
    )
}}

/*
    Model: stg_product_recall
    Description: PV产品召回记录原始数据清洗层 - Staging层
    Source: PV系统产品召回记录表
    Grain: 每行代表一条产品召回记录
*/

with source_data as (
    select * from {{ source('pv_raw', 'pv_product_recall') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        recall_id,
        recall_code,
        recall_level,
        recall_reason,
        recall_scope,
        product_id,
        batch_numbers,
        recall_date,
        notification_date,
        recall_qty as recall_quantity,
        recall_unit,
        actual_return_qty as actual_return_quantity,
        status as recall_status,
        responsible,
        regulatory_report_date,
        close_date,
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
