{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['staging', 'erp', 'procurement']
    )
}}

/*
    Model: stg_purchase_order_detail
    Description: ERP采购订单明细原始数据清洗层 - Staging层
    Source: ERP系统采购订单明细表
    Grain: 每行代表一个采购订单明细项
*/

with source_data as (
    select * from {{ source('erp_raw', 'erp_purchase_order_detail') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        -- 主键
        pod_id as purchase_order_detail_id,

        -- 外键
        po_number as purchase_order_number,
        material_id,

        -- 数量和金额
        quantity,
        unit,
        unit_price,
        amount,

        -- 交付信息
        delivery_qty as delivered_quantity,
        inspection_status,
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