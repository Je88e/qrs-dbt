{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='work_order_operation_id',
        merge_exclude_columns=['snowflake_id'],
        on_schema_change='append_new_columns',
        tags=['staging', 'mes', 'production']
    )
}}

/*
    Model: stg_work_order_operation
    Description: MES工单工序执行原始数据清洗层 - Staging层
    Source: MES系统工单工序执行表
    Grain: 每行代表一个工单工序执行记录
*/

with source_data as (
    select * from {{ source('mes_raw', 'mes_work_order_operation') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        woo_id as work_order_operation_id,
        wo_number as work_order_number,
        operation_id,
        sequence as operation_sequence,
        planned_start,
        planned_end,
        actual_start,
        actual_end,
        status  as operation_status,
        equipment_id,
        operator_id,
        yield_qty as yield_quantity,
        defect_qty as defect_quantity,
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