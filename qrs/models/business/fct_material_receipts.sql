{{
    config(
        materialized='view',
        tags=['erp', 'procurement', 'quality', 'pqr']
    )
}}

/*
    Model: fct_material_receipts
    Description: 物料接收事实表 - 记录物料接收入库的完整信息，关联采购订单和仓库信息
*/

-- 1. Import CTEs: 显式声明所有依赖
with material_receipt as (
    select * from {{ ref('stg_material_receipt') }}
),

purchase_order as (
    select * from {{ ref('stg_purchase_order') }}
),

material as (
    select * from {{ ref('stg_material_master') }}
),

warehouse as (
    select * from {{ ref('stg_warehouse') }}
),

storage_location as (
    select * from {{ ref('stg_storage_location') }}
),

-- 2. Logic CTEs: 业务逻辑处理
final as (
    select
        -- 接收记录主键
        mr.receipt_id,

        -- 关联采购订单
        mr.purchase_order_number,
        po.supplier_id,

        -- 物料信息
        mr.material_id,
        m.material_name,
        m.material_type,
        m.specification as material_specification,
        mr.batch_number,

        -- 接收数量
        mr.receipt_quantity,
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

        -- 审计字段
        mr.created_at

    from material_receipt mr
    left join purchase_order po on mr.purchase_order_number = po.purchase_order_number
    left join material m on mr.material_id = m.material_id
    left join warehouse wh on mr.warehouse_id = wh.warehouse_id
    left join storage_location sl on mr.location_id = sl.location_id
)

-- 3. Output: 必须选择 Final CTE
select * from final

