{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='inventory_id',
        merge_exclude_columns=['snowflake_id'],
        on_schema_change='append_new_columns',
        tags=['staging', 'erp', 'inventory']
    )
}}

/*
    Model: stg_inventory
    Description: ERP库存主数据原始数据清洗层 - Staging层
    Source: ERP系统库存主数据表
    Grain: 每行代表一个库存记录
*/

with source_data as (
    select * from {{ source('erp_raw', 'erp_inventory') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        inventory_id,
        material_id,
        batch_number,
        warehouse_id,
        location_id,
        quantity as current_quantity,
        unit,
        inventory_status,
        expiry_date,
        last_count_date,
        last_count_qty as last_count_quantity,
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