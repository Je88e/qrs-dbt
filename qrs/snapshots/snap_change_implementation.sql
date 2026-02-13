{% snapshot snap_change_implementation %}

{{
    config(
        target_schema='snapshots',
        unique_key='implementation_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['staging', 'qms', 'quality', 'audit'],
        
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
        }
    )
}}

/*
    Snapshot: snap_change_implementation
        Description: QMS变更实施记录快照
        
        业务场景:
        - 变更实施进度追踪
        - 实施状态变更历史
        - 审计追踪
        
        运行频率: 每日
*/

select
    snowflake_id,
    implementation_id,
    change_id,
    task_name,
    task_description,
    responsible,
    planned_start,
    planned_end,
    actual_start,
    actual_end,
    task_status,
    completion_evidence,
    reviewer,
    review_date,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_change_implementation') }}

{% endsnapshot %}
