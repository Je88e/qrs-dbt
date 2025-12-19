{{
    config(
        materialized='view',
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
        equipment_id,
        equipment_code,
        equipment_name,
        equipment_type,
        manufacturer,
        model,
        serial_number,
        installation_date,
        workshop_id,
        production_line_id,
        equipment_status,
        last_maintenance_date,
        next_maintenance_date,
        created_at
    from source_data
)

select * from final