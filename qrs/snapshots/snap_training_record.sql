{% snapshot snap_training_record %}

{{
    config(
        target_schema='snapshots',
        unique_key='training_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['staging', 'qms', 'hr', 'audit'],
        
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
        }
    )
}}

/*
    Snapshot: snap_training_record
        Description: QMS培训记录快照
        
        业务场景:
        - 培训状态变更追踪
        - 培训历史记录
        - 审计追踪
        
        追踪字段: training_status
        运行频率: 每日
*/

select
    snowflake_id,
    training_id,
    personnel_id,
    course_code,
    course_name,
    course_type,
    training_date,
    training_duration,
    trainer,
    assessment_score,
    assessment_result,
    certificate_no,
    valid_from,
    valid_to,
    training_status,
    create_date,
    CAST(COALESCE(loaded_at, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_training_record') }}

{% endsnapshot %}
