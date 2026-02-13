{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='work_order_number',
        merge_exclude_columns=['snowflake_id'],
        on_schema_change='append_new_columns',
        tags=['staging', 'mes', 'production']
    )
}}

/*
    Model: stg_work_order
    Description: MES生产工单原始数据清洗层 - Staging层
    Source: MES系统生产工单主表
    Grain: 每行代表一个生产工单
*/

with source_data as (
    select * from {{ source('mes_raw', 'mes_work_order') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        wo_number as work_order_number,
        product_id,
        batch_number,
        planned_qty as planned_quantity,
        actual_qty as actual_quantity,
        unit,
        wo_status as work_order_status,
        plan_start_date as planned_start_date,
        plan_end_date as planned_end_date,
        actual_start_date,
        actual_end_date,
        workshop_id,
        create_by,
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