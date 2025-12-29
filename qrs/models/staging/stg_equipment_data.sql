{{
    config(
        materialized='view',
        tags=['staging', 'scada', 'monitoring']
    )
}}

/*
    Model: stg_equipment_data
    Description: SCADA设备运行数据原始数据清洗层 - Staging层
    Source: SCADA系统设备运行数据采集表
    Grain: 每行代表一条设备运行数据记录
*/

with source_data as (
    select * from {{ source('scada_raw', 'scada_equipment_data') }}
),

final as (
    select
        data_id,
        equipment_id,
        parameter_name,
        parameter_value,
        unit,
        collection_time,
        quality_code,
        batch_number,
        wo_number as work_order_number,
        operation_id,
        create_date
    from source_data
)

select * from final