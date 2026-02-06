{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['staging', 'scada', 'production']
    )
}}

/*
    Model: stg_batch_tracking
    Description: SCADA批次追踪记录原始数据清洗层 - Staging层
    Source: SCADA系统批次追踪记录表
    Grain: 每行代表一条批次追踪记录
*/

with source_data as (
    select * from {{ source('scada_raw', 'scada_batch_tracking') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        tracking_id,
        batch_number,
        wo_number as work_order_number,
        product_id,
        operation_id,
        equipment_id,
        start_time,
        end_time,
        status as tracking_status,
        operator_id,
        yield_qty as yield_quantity,
        unit,
        quality_status,
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