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