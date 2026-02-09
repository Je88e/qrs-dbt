{{
    config(
        materialized='view',
        tags=['erp', 'supplier', 'quality', 'pqr']
    )
}}

/*
    Model: fct_supplier_performance
    Description: 供应商绩效跟踪 - 整合供应商的交付质量、审计结果、退货情况
*/

with supplier as (
    select * from {{ ref('stg_supplier_master') }}
),

material_receipt as (
    select * from {{ ref('stg_material_receipt') }}
),

material_return as (
    select * from {{ ref('stg_material_return') }}
),

supplier_audit as (
    select * from {{ ref('stg_supplier_audit') }}
),

inspection_result as (
    select * from {{ ref('stg_inspection_result') }}
),

-- 统计每个供应商的接收批次数
receipt_stats as (
    select
        mr.purchase_order_number,
        po.supplier_id,
        count(distinct mr.receipt_id) as total_receipts
    from material_receipt mr
    left join {{ ref('stg_purchase_order') }} po on mr.purchase_order_number = po.purchase_order_number
    group by mr.purchase_order_number, po.supplier_id
),

supplier_receipt_agg as (
    select
        supplier_id,
        sum(total_receipts) as total_receipts
    from receipt_stats
    where supplier_id is not null
    group by supplier_id
),

-- 统计每个供应商的退货批次数
return_stats as (
    select
        supplier_id,
        count(distinct return_id) as total_returns
    from material_return
    where supplier_id is not null
    group by supplier_id
),

-- 获取最新审计记录
latest_audit as (
    select
        supplier_id,
        audit_score as latest_audit_score,
        audit_result as latest_audit_result,
        audit_date as latest_audit_date,
        row_number() over (partition by supplier_id order by audit_date desc) as rn
    from supplier_audit
),

latest_audit_filtered as (
    select * from latest_audit where rn = 1
),

final as (
    select
        -- 供应商主键
        s.supplier_id,
        s.supplier_name,
        s.supplier_type,
        s.qualification_status,

        -- 接收统计
        coalesce(sra.total_receipts, 0) as total_receipts,

        -- 退货统计
        coalesce(rs.total_returns, 0) as total_returns,

        -- 退货率
        case
            when coalesce(sra.total_receipts, 0) > 0
            then round(coalesce(rs.total_returns, 0)::numeric / sra.total_receipts * 100, 2)
            else 0
        end as return_rate_percent,

        -- 审计信息
        la.latest_audit_score,
        la.latest_audit_result,
        la.latest_audit_date,

        -- 绩效等级
        case
            when la.latest_audit_score >= 90 and coalesce(rs.total_returns, 0)::numeric / nullif(sra.total_receipts, 0) * 100 < 2 then 'A'
            when la.latest_audit_score >= 80 and coalesce(rs.total_returns, 0)::numeric / nullif(sra.total_receipts, 0) * 100 < 5 then 'B'
            when la.latest_audit_score >= 70 and coalesce(rs.total_returns, 0)::numeric / nullif(sra.total_receipts, 0) * 100 < 10 then 'C'
            else 'D'
        end as performance_level,

        -- 审计字段
        s.create_date

    from supplier s
    left join supplier_receipt_agg sra on s.supplier_id = sra.supplier_id
    left join return_stats rs on s.supplier_id = rs.supplier_id
    left join latest_audit_filtered la on s.supplier_id = la.supplier_id
)

select * from final
