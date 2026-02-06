{{
    config(
        materialized='view',
        tags=['scada', 'equipment', 'monitoring', 'pqr']
    )
}}

/*
    Model: fct_equipment_monitoring
    Description: 提供设备运行参数的实时监控数据
*/

with equipment_data as (
    select * from {{ ref('stg_equipment_data') }}
),

equipment as (
    select * from {{ ref('stg_equipment') }}
),

work_order as (
    select * from {{ ref('stg_work_order') }}
),

operation as (
    select * from {{ ref('stg_operation') }}
)

select
    -- 数据主键
    ed.data_id,
    
    -- 设备信息
    ed.equipment_id,
    eq.equipment_code,
    eq.equipment_name,
    eq.equipment_type,
    
    -- 参数信息
    ed.param_name,
    ed.param_value,
    ed.unit,
    ed.quality_code,
    
    -- 采集时间
    ed.collection_time,
    
    -- 关联生产信息
    ed.batch_number,
    ed.work_order_number,
    wo.product_id,
    ed.operation_id,
    op.operation_name,
    
    -- 审计字段
    ed.create_date

from equipment_data ed
left join equipment eq on ed.equipment_id = eq.equipment_id
left join work_order wo on ed.work_order_number = wo.work_order_number
left join operation op on ed.operation_id = op.operation_id

