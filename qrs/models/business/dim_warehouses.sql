{{
    config(
        materialized='view',
        tags=['erp', 'inventory', 'master_data', 'pqr']
    )
}}

/*
    Model: dim_warehouses
    Description: 整合仓库主表和库位表，提供完整的仓储信息视图
*/

with warehouse as (
    select * from {{ ref('stg_warehouse') }}
),

storage_location as (
    select * from {{ ref('stg_storage_location') }}
)

select
    -- 仓库主键
    wh.warehouse_id,
    
    -- 仓库信息
    wh.warehouse_name,
    wh.warehouse_type,
    wh.address,
    wh.warehouse_area,
    wh.manager,
    wh.contact_phone,
    wh.warehouse_status,
    
    -- 库位信息
    sl.location_id,
    sl.location_code,
    sl.location_name,
    sl.location_type,
    sl.capacity,
    sl.capacity_unit,
    sl.current_usage,
    sl.location_status,
    
    -- 容量使用率
    case 
        when sl.capacity > 0 then round(cast(sl.current_usage as decimal) / sl.capacity * 100, 2)
        else 0
    end as usage_rate_percent,
    
    -- 审计字段
    wh.create_date as warehouse_create_date,
    sl.create_date as location_create_date

from warehouse wh
left join storage_location sl on wh.warehouse_id = sl.warehouse_id

