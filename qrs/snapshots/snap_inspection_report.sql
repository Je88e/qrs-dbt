{% snapshot snap_inspection_report %}

{{
    config(
        target_schema='snapshots',
        unique_key='report_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['staging', 'lims', 'quality', 'audit'],
        
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
        }
    )
}}

/*
    Snapshot: snap_inspection_report
        Description: LIMS检验报告快照
        
        业务场景:
        - 检验报告状态变更追踪
        - 检验结果历史记录
        - 审计追踪
        
        追踪字段: report_status
        运行频率: 每日
*/

select
    snowflake_id,
    report_id,
    request_id,
    report_code,
    sample_id,
    material_id,
    batch_number,
    conclusion,
    report_date,
    reporter,
    reviewer,
    review_date,
    approver,
    approval_date,
    report_status,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_inspection_report') }}

{% endsnapshot %}
