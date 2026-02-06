{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['staging', 'erp', 'procurement', 'quality']
    )
}}

/*
    Model: stg_material_receipt
    Description: ERP物料接收记录原始数据清洗层 - Staging层
    Source: ERP系统物料接收记录表
    Grain: 每行代表一条物料接收记录
*/

with source_data as (
    select * from {{ source('erp_raw', 'erp_material_receipt') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        -- 主键
        receipt_id,

        -- 外键
        po_number as purchase_order_number,
        material_id,
        warehouse_id,
        location_id,

        -- 批次信息
        batch_number,

        -- 数量信息
        received_qty as receipt_quantity,
        unit,

        -- 接收信息
        receipt_date,
        receiver,

        -- 检验状态
        inspection_status,
        inspection_result,

        -- 审计字段
        create_date,
        update_date,
        _airbyte_extracted_at as loaded_at
    from source_data
)

select * from final
{% if is_incremental() %}
where loaded_at > (
    select coalesce(max(loaded_at), '1900-01-01'::timestamp)
           - interval '{{ var("incremental_lookback_minutes", 5) }} minutes'
    from {{ this }}
)
{% endif %}

