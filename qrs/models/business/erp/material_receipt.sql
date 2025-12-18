{{
    config(
        materialized='view',
        tags=['erp', 'procurement', 'quality', 'pqr']
    )
}}

/*
 * 物料接收业务模型
 * 数据来源: ERP系统
 * 业务描述: 记录物料接收入库的完整信息，关联采购订单和仓库信息
 */

with material_receipt as (
    select * from {{ ref('erp_material_receipt') }}
),

purchase_order as (
    select * from {{ ref('erp_purchase_order') }}
),

material as (
    select * from {{ ref('erp_material_master') }}
),

warehouse as (
    select * from {{ ref('erp_warehouse') }}
),

storage_location as (
    select * from {{ ref('erp_storage_location') }}
)

select
    -- 接收记录主键
    mr.receipt_id,
    
    -- 关联采购订单
    mr.po_number as purchase_order_number,
    po.supplier_id,
    
    -- 物料信息
    mr.material_id,
    m.material_name,
    m.material_type,
    m.specification as material_specification,
    mr.batch_number,
    
    -- 接收数量
    mr.received_qty as received_quantity,
    mr.unit,
    mr.receipt_date,
    mr.receiver,
    
    -- 仓库信息
    mr.warehouse_id,
    wh.warehouse_name,
    wh.warehouse_type,
    mr.location_id,
    sl.location_name,
    
    -- 检验信息
    mr.inspection_status,
    mr.inspection_result,
    
    -- 审计字段
    mr.create_date

from material_receipt mr
left join purchase_order po on mr.po_number = po.po_number
left join material m on mr.material_id = m.material_id
left join warehouse wh on mr.warehouse_id = wh.warehouse_id
left join storage_location sl on mr.location_id = sl.location_id

