{{
    config(
        materialized='view',
        tags=['erp', 'procurement', 'pqr']
    )
}}

/*
 * 采购订单业务模型
 * 数据来源: ERP系统
 * 业务描述: 整合采购订单主表和明细表，提供完整的采购订单信息视图
 */

with purchase_order as (
    select * from {{ ref('erp_purchase_order') }}
),

purchase_order_detail as (
    select * from {{ ref('erp_purchase_order_detail') }}
),

supplier as (
    select * from {{ ref('erp_supplier_master') }}
),

material as (
    select * from {{ ref('erp_material_master') }}
)

select
    -- 采购订单主键
    po.po_number as purchase_order_number,
    pod.pod_id as purchase_order_detail_id,
    
    -- 供应商信息
    po.supplier_id,
    s.supplier_name,
    s.supplier_type,
    
    -- 物料信息
    pod.material_id,
    m.material_name,
    m.material_type,
    m.specification as material_specification,
    
    -- 订单信息
    po.po_type as order_type,
    po.po_status as order_status,
    po.order_date,
    po.expected_delivery_date,
    po.actual_delivery_date,
    
    -- 金额信息
    pod.quantity as order_quantity,
    pod.unit,
    pod.unit_price,
    pod.amount as line_amount,
    po.total_amount,
    po.currency,
    
    -- 交付信息
    pod.delivery_qty as delivered_quantity,
    pod.inspection_status,
    
    -- 审批信息
    po.buyer,
    po.approver,
    po.approval_date,
    
    -- 审计字段
    po.create_date,
    po.update_date

from purchase_order po
left join purchase_order_detail pod on po.po_number = pod.po_number
left join supplier s on po.supplier_id = s.supplier_id
left join material m on pod.material_id = m.material_id

