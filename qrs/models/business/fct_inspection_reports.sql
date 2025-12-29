{{
    config(
        materialized='view',
        tags=['lims', 'quality', 'inspection', 'pqr']
    )
}}

/*
    Model: fct_inspection_reports
    Description: 提供检验报告信息
*/

with inspection_report as (
    select * from {{ ref('stg_inspection_report') }}
),

inspection_request as (
    select * from {{ ref('stg_inspection_request') }}
),

sample as (
    select * from {{ ref('stg_sample') }}
),

material as (
    select * from {{ ref('stg_material_master') }}
)

select
    -- 报告主键
    rpt.report_id,
    
    -- 报告信息
    rpt.report_code,
    
    -- 关联申请
    rpt.request_id,
    ir.inspection_type,
    
    -- 样品信息
    rpt.sample_id,
    s.sample_code,
    
    -- 物料信息
    rpt.material_id,
    m.material_name,
    m.material_type,
    rpt.batch_number,
    
    -- 检验结论
    rpt.conclusion,
    
    -- 报告日期
    rpt.report_date,
    
    -- 报告人员
    rpt.reporter,
    
    -- 审核信息
    rpt.reviewer,
    rpt.review_date,
    
    -- 批准信息
    rpt.approver,
    rpt.approval_date,
    
    -- 报告状态
    rpt.report_status,
    
    -- 审计字段
    rpt.create_date

from inspection_report rpt
left join inspection_request ir on rpt.request_id = ir.request_id
left join sample s on rpt.sample_id = s.sample_id
left join material m on rpt.material_id = m.material_id

