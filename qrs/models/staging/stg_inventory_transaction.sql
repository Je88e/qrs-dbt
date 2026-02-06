{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
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