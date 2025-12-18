{{
    config(
        materialized='view',
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

renamed as (
    select
        maintenance_id,
        equipment_id,
        maintenance_type,
        maintenance_date,
        maintenance_duration,
        maintenance_description,
        maintenance_result,
        technician_id,
        created_at
    from source_data
)

select * from renamed

