{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['staging', 'mes', 'master_data']
    )
}}

/*
    Model: stg_equipment
    Description: MES设备主数据原始数据清洗层 - Staging层
    Source: MES系统设备主数据表
    Grain: 每行代表一台设备
*/

with source_data as (
    select * from {{ source('mes_raw', 'mes_equipment') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        equipment_id,
        equipment_code,
        equipment_name,
        equipment_type,
        manufacturer,
        model as equipment_model,
        serial_number,
        installation_date,
        workshop_id,
        line_id,
        status as equipment_status,
        last_maintenance_date,
        next_maintenance_date,
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