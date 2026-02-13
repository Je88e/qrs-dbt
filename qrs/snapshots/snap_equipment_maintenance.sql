{% snapshot snap_equipment_maintenance %}

{{
    config(
        target_schema='snapshots',
        unique_key='maintenance_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['staging', 'mes', 'equipment', 'audit'],
        
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
        }
    )
}}

/*
    Snapshot: snap_equipment_maintenance
        Description: MES设备维护记录快照
        
        业务场景:
        - 维护状态变更追踪
        - 维护历史记录
        - 审计追踪
        
        追踪字段: maintenance_status
        运行频率: 每日
*/

select
    snowflake_id,
    maintenance_id,
    equipment_id,
    maintenance_type,
    maintenance_date,
    maintenance_content,
    maintenance_result,
    downtime_hours,
    technician,
    reviewer,
    review_status,
    next_maintenance_date,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_equipment_maintenance') }}

{% endsnapshot %}
