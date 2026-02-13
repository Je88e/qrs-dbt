{% snapshot snap_equipment_data %}

{{
    config(
        target_schema='snapshots',
        unique_key='data_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['staging', 'scada', 'equipment', 'audit'],
        
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
        }
    )
}}

/*
    Snapshot: snap_equipment_data
        Description: SCADA设备运行数据快照
        
        业务场景:
        - 设备运行状态变更追踪
        - 设备性能分析历史
        - 审计追踪
        
        运行频率: 每小时
*/

select
    snowflake_id,
    data_id,
    equipment_id,
    param_name,
    param_value,
    unit,
    collection_time,
    quality_code,
    batch_number,
    work_order_number,
    operation_id,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_equipment_data') }}

{% endsnapshot %}
