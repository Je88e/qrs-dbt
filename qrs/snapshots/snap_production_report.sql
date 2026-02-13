{% snapshot snap_production_report %}

{{
    config(
        target_schema='snapshots',
        unique_key='report_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['staging', 'mes', 'production', 'audit'],
        
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
        }
    )
}}

/*
    Snapshot: snap_production_report
        Description: MES生产报告快照
        
        业务场景:
        - 生产报告状态变更追踪
        - 生产数据历史记录
        - 审计追踪
        
        追踪字段: report_status
        运行频率: 每日
*/

select
    snowflake_id,
    report_id,
    work_order_number,
    operation_id,
    batch_number,
    report_date,
    shift,
    output_quantity,
    defect_quantity,
    defect_reason,
    scrap_quantity,
    scrap_reason,
    operator_id,
    reviewer_id,
    review_status,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_production_report') }}

{% endsnapshot %}
