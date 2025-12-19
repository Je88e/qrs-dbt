{{
    config(
        materialized='view',
        tags=['mes', 'equipment', 'master_data', 'pqr']
    )
}}

/*
    Model: dim_equipment
    Description: 提供设备主数据信息，关联车间和产线
*/

with equipment as (
    select * from {{ ref('stg_equipment') }}
),

workshop as (
    select * from {{ ref('stg_workshop') }}
),

production_line as (
    select * from {{ ref('stg_production_line') }}
)

select
    -- 设备主键
    eq.equipment_id,
    
    -- 设备信息
    eq.equipment_code,
    eq.equipment_name,
    eq.equipment_type,
    eq.manufacturer,
    eq.model,
    eq.serial_number,
    eq.installation_date,
    
    -- 车间信息
    eq.workshop_id,
    ws.workshop_name,
    ws.workshop_type,
    
    -- 产线信息
    eq.line_id,
    pl.line_name,
    pl.product_type,
    
    -- 设备状态
    eq.status as equipment_status,
    
    -- 维护信息
    eq.last_maintenance_date,
    eq.next_maintenance_date,
    
    -- 维护到期天数
    case
        when eq.next_maintenance_date is not null
        then {{ date_diff_days('eq.next_maintenance_date', 'current_date') }}
        else null
    end as days_until_maintenance,
    
    -- 审计字段
    eq.create_date

from equipment eq
left join workshop ws on eq.workshop_id = ws.workshop_id
left join production_line pl on eq.line_id = pl.line_id

