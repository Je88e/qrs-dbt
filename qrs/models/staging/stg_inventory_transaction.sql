{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='transaction_id',
        merge_exclude_columns=['snowflake_id'],
        on_schema_change='append_new_columns',
        tags=['staging', 'erp', 'inventory']
    )
}}

/*
    Model: stg_inventory_transaction
    Description: ERP库存事务记录原始数据清洗层 - Staging层
    Source: ERP系统库存事务记录表
    Grain: 每行代表一条库存事务记录
*/

with source_data as (
    select * from {{ source('erp_raw', 'erp_inventory_transaction') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        transaction_id,
        inventory_id,
        material_id,
        batch_number,
        transaction_type,
        quantity as transaction_quantity,
        unit as transaction_unit,
        transaction_date,
        reference_doc,
        reference_type,
        operator as operator_name,
        remark,
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