{{
    config(
        materialized='view',
        tags=['erp', 'inventory', 'pqr']
    )
}}

/*
    Model: fct_inventory
    Description: 整合库存主表和事务表，提供完整的库存信息视图
*/

with inventory as (
    select * from {{ ref('stg_inventory') }}
),

inventory_transaction as (
    select * from {{ ref('stg_inventory_transaction') }}
),

material as (
    select * from {{ ref('stg_material_master') }}
),

warehouse as (
    select * from {{ ref('stg_warehouse') }}
),

storage_location as (
    select * from {{ ref('stg_storage_location') }}
)

select
    -- 库存主键
    inv.inventory_id,
    
    -- 物料信息
    inv.material_id,
    m.material_name,
    m.material_type,
    m.material_specification,
    inv.batch_number,
    
    -- 仓库位置
    inv.warehouse_id,
    wh.warehouse_name,
    wh.warehouse_type,
    inv.location_id,
    sl.location_name,
    sl.location_code,
    
    -- 库存数量
    inv.current_quantity,
    inv.unit,
    inv.inventory_status,
    
    -- 有效期
    inv.expiry_date,
    
    -- 盘点信息
    inv.last_count_date,
    inv.last_count_quantity,
    
    -- 审计字段
    inv.create_date,
    inv.update_date

from inventory inv
left join material m on inv.material_id = m.material_id
left join warehouse wh on inv.warehouse_id = wh.warehouse_id
left join storage_location sl on inv.location_id = sl.location_id

