{{
    config(
        materialized='view',
        tags=['mes', 'production', 'quality', 'pqr']
    )
}}

/*
    Model: fct_production_reports
    Description: 记录生产报工信息，用于产量统计和质量分析
*/

with production_report as (
    select * from {{ ref('stg_production_report') }}
),

work_order as (
    select * from {{ ref('stg_work_order') }}
),

operation as (
    select * from {{ ref('stg_operation') }}
),

personnel as (
    select * from {{ ref('stg_personnel') }}
)

select
    -- 报工主键
    pr.report_id,
    
    -- 关联工单
    pr.work_order_number,
    wo.product_id,
    pr.batch_number,
    
    -- 工序信息
    pr.operation_id,
    op.operation_name,
    op.operation_type,
    
    -- 报工日期和班次
    pr.report_date,
    pr.shift,
    
    -- 产量信息
    pr.output_quantity,
    pr.defect_quantity,
    pr.defect_reason,
    pr.scrap_quantity,
    pr.scrap_reason,
    
    -- 良品率计算
    case 
        when pr.output_quantity > 0 then round((cast(pr.output_quantity as decimal) - pr.defect_quantity) / pr.output_quantity * 100, 2)
        else 0
    end as yield_rate_percent,
    
    -- 操作员信息
    pr.operator_id,
    per_op.personnel_name as operator_name,
    
    -- 审核信息
    pr.reviewer_id,
    per_rv.personnel_name as reviewer_name,
    pr.review_status,
    
    -- 审计字段
    pr.create_date

from production_report pr
left join work_order wo on pr.work_order_number = wo.work_order_number
left join operation op on pr.operation_id = op.operation_id
left join personnel per_op on pr.operator_id = per_op.personnel_id
left join personnel per_rv on pr.reviewer_id = per_rv.personnel_id

