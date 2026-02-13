{% snapshot snap_supplier_audit %}

{{
    config(
        target_schema='snapshots',
        unique_key='audit_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['staging', 'qms', 'procurement', 'audit'],
        
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
        }
    )
}}

/*
    Snapshot: snap_supplier_audit
        Description: QMS供应商审计快照
        
        业务场景:
        - 审计状态变更追踪
        - 审计历史记录
        - 审计追踪
        
        追踪字段: audit_status
        运行频率: 每日
*/

select
    snowflake_id,
    audit_id,
    audit_code,
    supplier_id,
    audit_type,
    audit_date,
    audit_scope,
    auditor,
    audit_result,
    audit_score,
    findings_count,
    critical_findings,
    major_findings,
    minor_findings,
    observations,
    follow_up_required,
    follow_up_date,
    audit_status,
    report_date,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_supplier_audit') }}

{% endsnapshot %}
