{{
    config(
        materialized='view',
        tags=['staging', 'qms', 'quality']
    )
}}

/*
    Model: stg_supplier_audit
    Description: QMS供应商审计记录原始数据清洗层 - Staging层
    Source: QMS系统供应商审计记录表
    Grain: 每行代表一条供应商审计记录
*/

with source_data as (
    select * from {{ source('qms_raw', 'qms_supplier_audit') }}
),

final as (
    select
        audit_id,
        audit_code,
        supplier_id,
        audit_type,
        audit_date,
        audit_scope,
        auditor,
        audit_result,
        score as audit_score,
        findings_count,
        critical_findings,
        major_findings,
        minor_findings,
        observations,
        follow_up_required,
        follow_up_date,
        status as audit_status,
        report_date,
        create_date
    from source_data
)

select * from final