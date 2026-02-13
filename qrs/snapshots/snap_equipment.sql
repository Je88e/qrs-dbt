{% snapshot snap_equipment %}

{{
    config(
        target_schema='snapshots',
        unique_key='equipment_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['staging', 'mes', 'master_data', 'audit'],
        
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
        }
    )
}}

/*
    Snapshot: snap_equipment
        Description: MES设备主数据快照
        
        业务场景:
        - 设备信息变更追踪
        - 设备状态历史记录
        - 审计追踪
        
        追踪字段: equipment_status
        运行频率: 每日
*/

select
    snowflake_id,
    equipment_id,
    equipment_code,
    equipment_name,
    equipment_type,
    manufacturer,
    equipment_model,
    serial_number,
    installation_date,
    workshop_id,
    line_id,
    equipment_status,
    last_maintenance_date,
    next_maintenance_date,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_equipment') }}

{% endsnapshot %}
