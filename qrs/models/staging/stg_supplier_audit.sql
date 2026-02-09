{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
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
        -- 新增雪花ID
        {{ generate_snowflake_id() }}::text as snowflake_id,
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
        create_date,
        update_date,
        CAST(_airbyte_extracted_at AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at
    from source_data
)

select * from final
{% if is_incremental() %}
where loaded_at > (
    select coalesce(max(loaded_at), CAST('1900-01-01 00:00:00.000 +0800' AS timestamptz))
           - interval '{{ var("incremental_lookback_minutes", 5) }} minutes'
    from {{ this }}
)
{% endif %}