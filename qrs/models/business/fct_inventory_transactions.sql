{{
    config(
        materialized='view',
        tags=['erp', 'inventory', 'pqr']
    )
}}

/*
    Model: fct_inventory_transactions
    Description: 记录所有库存变动的事务信息，用于追溯和分析
*/

with inventory_transaction as (
    select * from {{ ref('stg_inventory_transaction') }}
),

inventory as (
    select * from {{ ref('stg_inventory') }}
),

material as (
    select * from {{ ref('stg_material_master') }}
)

select
    -- 事务主键
    it.transaction_id,
    
    -- 关联库存
    it.inventory_id,
    
    -- 物料信息
    it.material_id,
    m.material_name,
    m.material_type,
    it.batch_number,
    
    -- 事务信息
    it.transaction_type,
    it.transaction_quantity,
    it.transaction_unit,
    it.transaction_date,
    
    -- 参考信息
    it.reference_doc,
    it.reference_type,
    
    -- 操作信息
    it.operator_name,
    it.remark,
    
    -- 审计字段
    it.create_date

from inventory_transaction it
left join inventory inv on it.inventory_id = inv.inventory_id
left join material m on it.material_id = m.material_id

