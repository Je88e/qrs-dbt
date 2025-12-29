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

final as (
    select
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
        create_date
    from source_data
)

select * from final