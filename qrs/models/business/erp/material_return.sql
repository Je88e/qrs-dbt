{{
    config(
        materialized='view',
        tags=['erp', 'procurement', 'quality', 'pqr']
    )
}}

/*
 * 物料退货业务模型
 * 数据来源: ERP系统
 * 业务描述: 记录物料退货的完整信息，用于质量分析和供应商评估
 */

with material_return as (
    select * from {{ ref('erp_material_return') }}
),

material_receipt as (
    select * from {{ ref('erp_material_receipt') }}
),

material as (
    select * from {{ ref('erp_material_master') }}
),

supplier as (
    select * from {{ ref('erp_supplier_master') }}
)

select
    -- 退货记录主键
    mr.return_id,
    
    -- 关联接收记录
    mr.receipt_id,
    rec.po_number as purchase_order_number,
    
    -- 物料信息
    mr.material_id,
    m.material_name,
    m.material_type,
    mr.batch_number,
    
    -- 退货信息
    mr.return_qty as return_quantity,
    mr.unit,
    mr.return_reason,
    mr.return_type,
    mr.return_date,
    mr.return_status,
    
    -- 供应商信息
    mr.supplier_id,
    s.supplier_name,
    s.supplier_type,
    
    -- 处理信息
    mr.processor,
    
    -- 审计字段
    mr.create_date

from material_return mr
left join material_receipt rec on mr.receipt_id = rec.receipt_id
left join material m on mr.material_id = m.material_id
left join supplier s on mr.supplier_id = s.supplier_id

