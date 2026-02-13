{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='energy_id',
        merge_exclude_columns=['snowflake_id'],
        on_schema_change='append_new_columns',
        tags=['staging', 'scada', 'monitoring']
    )
}}

/*
    Model: stg_energy_consumption
    Description: SCADA能耗监控数据原始数据清洗层 - Staging层
    Source: SCADA系统能耗监控数据表
    Grain: 每行代表一条能耗监控数据记录
*/

with source_data as (
    select * from {{ source('scada_raw', 'scada_energy_consumption') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        energy_id,
        equipment_id,
        workshop_id,
        energy_type,
        consumption_value,
        unit,
        collection_date,
        collection_hour,
        wo_number as work_order_number,
        batch_number,
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