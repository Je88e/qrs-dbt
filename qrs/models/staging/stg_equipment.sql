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

renamed as (
    select
        equipment_id,
        equipment_name,
        equipment_type,
        equipment_model,
        production_line_id,
        workshop_id,
        equipment_status,
        installation_date,
        last_maintenance_date,
        next_maintenance_date,
        created_at,
        updated_at
    from source_data
)

select * from renamed

