{{
    config(
        materialized='incremental',
        unique_key='data_id',
        incremental_strategy='append',
        on_schema_change='append_new_columns',
        tags=['staging', 'scada', 'monitoring']
    )
}}

/*
    Model: stg_equipment_data
    Description: SCADA设备运行数据原始数据清洗层 - Staging层
    Source: SCADA系统设备运行数据采集表
    Grain: 每行代表一条设备运行数据记录

    升级说明:
    - 新增 snowflake_id: 分布式唯一标识符
    - 新增 _loaded_at: dbt处理时间戳，用于增量控制
    - 物化策略: incremental (append) - SCADA时序数据不更新，只追加
    - 回溯窗口: 2分钟（SCADA数据实时性高）
*/

with source_data as (
    select * from {{ source('scada_raw', 'scada_equipment_data') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,

        -- 原有字段
        data_id,
        equipment_id,
        parameter_name as param_name,
        parameter_value as param_value,
        unit,
        collection_time,
        quality_code,
        batch_number,
        wo_number as work_order_number,
        operation_id,
        create_date,
        update_date,
        CAST(_airbyte_extracted_at AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at
    from source_data
)

select * from final
{% if is_incremental() %}
where loaded_at > (
    select coalesce(max(loaded_at), CAST('1900-01-01 00:00:00.000 +0800' AS timestamptz))
           - interval '{{ var("high_frequency_lookback_minutes", 2) }} minutes'
    from {{ this }}
)
{% endif %}
