{{
    config(
        materialized='view',
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

renamed as (
    select
        consumption_id,
        equipment_id,
        energy_type,
        consumption_value,
        unit,
        timestamp,
        created_at
    from source_data
)

select * from renamed

