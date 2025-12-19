{{
    config(
        materialized='view',
        tags=['qms', 'quality', 'supplier', 'pqr']
    )
}}

/*
    Model: fct_supplier_audits
    Description: 提供供应商审计记录的完整信息
*/

with supplier_audit as (
    select * from {{ ref('stg_supplier_audit') }}
),

supplier as (
    select * from {{ ref('stg_supplier_master') }}
)

select
    -- 审计主键
    sa.audit_id,
    
    -- 审计信息
    sa.audit_code,
    sa.audit_type,
    sa.audit_date,
    sa.audit_scope,
    sa.auditor,
    
    -- 供应商信息
    sa.supplier_id,
    s.supplier_name,
    s.supplier_type,
    
    -- 审计结果
    sa.audit_result,
    sa.score as audit_score,
    
    -- 发现问题统计
    sa.findings_count,
    sa.critical_findings,
    sa.major_findings,
    sa.minor_findings,
    sa.observations,
    
    -- 后续跟踪
    sa.follow_up_required,
    sa.follow_up_date,
    
    -- 审计状态
    sa.status as audit_status,
    
    -- 报告日期
    sa.report_date,
    
    -- 审计字段
    sa.create_date

from supplier_audit sa
left join supplier s on sa.supplier_id = s.supplier_id

