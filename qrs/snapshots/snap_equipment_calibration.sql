{% snapshot snap_equipment_calibration %}

{{
    config(
        target_schema='snapshots',
        unique_key='calibration_id',
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
    Snapshot: snap_equipment_calibration
        Description: MES设备校准记录快照
        
        业务场景:
        - 校准状态变更追踪
        - 校准历史记录
        - 审计追踪
        
        追踪字段: calibration_status
        运行频率: 每日
*/

select
    snowflake_id,
    calibration_id,
    calibration_code,
    equipment_id,
    calibration_type,
    calibration_date,
    next_calibration_date,
    calibration_cycle,
    standard_equipment,
    standard_certificate,
    calibration_result,
    deviation_value,
    tolerance,
    is_within_tolerance,
    calibrator,
    reviewer,
    certificate_no, 
    calibration_status, 
    create_date,
    CAST(COALESCE(loaded_at, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_equipment_calibration') }}

{% endsnapshot %}
