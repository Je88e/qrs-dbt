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