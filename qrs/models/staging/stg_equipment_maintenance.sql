{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['staging', 'mes', 'maintenance']
    )
}}

/*
    Model: stg_equipment_maintenance
    Description: MES设备维护记录原始数据清洗层 - Staging层
    Source: MES系统设备维护记录表
    Grain: 每行代表一条设备维护记录
*/

with source_data as (
    select * from {{ source('mes_raw', 'mes_equipment_maintenance') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
        maintenance_id,
        equipment_id,
        maintenance_type,
        maintenance_date,
        maintenance_content,
        maintenance_result,
        downtime_hours,
        technician,
        reviewer,
        review_status,
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