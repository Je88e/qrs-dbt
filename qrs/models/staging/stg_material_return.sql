{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['staging', 'erp', 'procurement', 'quality']
    )
}}

/*
    Model: stg_material_return
    Description: ERP物料退货记录原始数据清洗层 - Staging层
    Source: ERP系统物料退货记录表
    Grain: 每行代表一条物料退货记录
*/

with source_data as (
    select * from {{ source('erp_raw', 'erp_material_return') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        -- 主键
        return_id,
        
        -- 外键
        receipt_id,
        material_id,
        
        -- 批次信息
        batch_number,
        
        -- 数量信息
        return_qty as return_quantity,
        unit,
        
        -- 退货信息
        return_reason,
        return_type,
        return_date,
        return_status,
        supplier_id,
        processor,
        
        -- 审计字段
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