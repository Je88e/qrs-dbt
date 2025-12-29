{{
    config(
        materialized='view',
        tags=['scada', 'energy', 'monitoring', 'pqr']
    )
}}

/*
    Model: fct_energy_consumption
    Description: 提供设备和车间的能耗监控数据
*/

with energy_consumption as (
    select * from {{ ref('stg_energy_consumption') }}
),

equipment as (
    select * from {{ ref('stg_equipment') }}
),

workshop as (
    select * from {{ ref('stg_workshop') }}
),

work_order as (
    select * from {{ ref('stg_work_order') }}
)

select
    -- 能耗主键
    ec.energy_id,
    
    -- 设备信息
    ec.equipment_id,
    eq.equipment_code,
    eq.equipment_name,
    eq.equipment_type,
    
    -- 车间信息
    ec.workshop_id,
    ws.workshop_name,
    
    -- 能耗信息
    ec.energy_type,
    ec.consumption_value,
    ec.unit,
    
    -- 时间信息
    ec.collection_date,
    ec.collection_hour,
    
    -- 关联生产信息
    ec.work_order_number,
    wo.product_id,
    ec.batch_number,
    
    -- 审计字段
    ec.create_date

from energy_consumption ec
left join equipment eq on ec.equipment_id = eq.equipment_id
left join workshop ws on ec.workshop_id = ws.workshop_id
left join work_order wo on ec.work_order_number = wo.work_order_number

