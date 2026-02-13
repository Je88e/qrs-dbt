{% snapshot snap_complaint %}

{{
    config(
        target_schema='snapshots',
        unique_key='complaint_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['staging', 'pv', 'safety', 'audit'],
        
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
        }
    )
}}

/*
    Snapshot: snap_complaint
        Description: PV投诉报告快照
        
        业务场景:
        - 投诉处理状态追踪
        - 投诉分析报告
        - 审计追踪
        
        追踪字段: complaint_status
        运行频率: 每日
*/

select
    snowflake_id,
    complaint_id,
    complaint_code,
    complaint_type,
    complaint_source,
    product_id,
    batch_number,
    complaint_date,
    receive_date,
    complaint_description,
    contact_name,
    contact_phone,
    priority,
    complaint_status,
    investigator,
    investigation_result,
    corrective_action,
    response_date,
    close_date,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_complaint') }}

{% endsnapshot %}
