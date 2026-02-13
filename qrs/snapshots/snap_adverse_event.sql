{% snapshot snap_adverse_event %}

{{
    config(
        target_schema='snapshots',
        unique_key='event_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['staging', 'pv', 'safety'],
        
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
        }
    )
}}

/*
snapshot_meta_column_names={
            'dbt_valid_from': 'valid_from',
            'dbt_valid_to': 'valid_to',
            'dbt_scd_id': 'snapshot_id',
            'dbt_updated_at': 'last_updated_at',
            'dbt_is_deleted': 'is_deleted'
        }
*/

/*
    Snapshot: snap_adverse_event
        Description: PV不良反应报告
        
        业务场景:
        - 药物不良反应报告追踪
        - 药物警戒分析
        - 审计追踪
        
        追踪字段: event_status
        运行频率: 每日
*/

select
    snowflake_id,
    event_id,
    event_code,
    product_id,
    batch_number,
    event_date,
    report_date,
    event_type,
    severity,
    event_description,
    patient_age,
    patient_gender,
    outcome,
    causality_assessment,
    reporter_type,
    reporter_name,
    event_status,
    investigator,
    close_date,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_adverse_event') }}

{% endsnapshot %}

