{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['staging', 'mes', 'production']
    )
}}

/*
    Model: stg_material_consumption
    Description: MES物料消耗记录原始数据清洗层 - Staging层
    Source: MES系统物料消耗记录表
    Grain: 每行代表一条物料消耗记录
*/

with source_data as (
    select * from {{ source('mes_raw', 'mes_material_consumption') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        consumption_id,
        wo_number as work_order_number,
        operation_id,
        material_id,
        batch_number,
        planned_qty as planned_quantity,
        actual_qty as actual_quantity,
        unit,
        consumption_date,
        operator_id,
        variance_reason,
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