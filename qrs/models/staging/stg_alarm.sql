{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='alarm_id',
        merge_exclude_columns=['snowflake_id'],
        on_schema_change='append_new_columns',
        tags=['staging', 'scada', 'monitoring']
    )
}}

/*
    Model: stg_alarm
    Description: SCADA报警记录原始数据清洗层 - Staging层
    Source: SCADA系统报警记录表
    Grain: 每行代表一条报警记录
*/

with source_data as (
    select * from {{ source('scada_raw', 'scada_alarm') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        alarm_id,
        equipment_id,
        location_code,
        alarm_type,
        alarm_level,
        alarm_message,
        alarm_time,
        ack_time as acknowledge_time,
        ack_by as acknowledged_by,
        resolve_time,
        resolve_by as resolved_by,
        alarm_status,
        related_batch as batch_number,
        related_wo as work_order_number,
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