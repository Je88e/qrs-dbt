{% snapshot snap_alarm %}

{{
    config(
        target_schema='snapshots',
        unique_key='alarm_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['staging', 'scada', 'monitoring', 'audit'],
        
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
        }
    )
}}

/*
    Snapshot: snap_alarm
        Description: SCADA报警记录快照
        
        业务场景:
        - 报警状态变更追踪
        - 设备故障历史分析
        - 审计追踪
        
        追踪字段: alarm_status
        运行频率: 每小时
*/

select
    snowflake_id,
    alarm_id,
    equipment_id,
    location_code,
    alarm_type,
    alarm_level,
    alarm_message,
    alarm_time,
    acknowledge_time,
    acknowledged_by,
    resolve_time,
    resolved_by,
    alarm_status,
    batch_number,
    work_order_number,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_alarm') }}

{% endsnapshot %}
