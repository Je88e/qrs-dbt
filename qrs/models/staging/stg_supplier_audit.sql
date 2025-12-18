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

renamed as (
    select
        audit_id,
        supplier_id,
        audit_type,
        audit_date,
        auditor,
        audit_result,
        audit_score,
        findings,
        corrective_actions,
        follow_up_date,
        created_at,
        updated_at
    from source_data
)

select * from renamed

