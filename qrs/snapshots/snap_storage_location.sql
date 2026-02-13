{% snapshot snap_storage_location %}

{{
    config(
        target_schema='snapshots',
        unique_key='location_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['staging', 'erp', 'master_data', 'audit'],
        
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
        }
    )
}}

/*
    Snapshot: snap_storage_location
        Description: ERP存储位置主数据快照
        
        业务场景:
        - 存储位置信息变更追踪
        - 库位状态历史记录
        - 审计追踪
        
        追踪字段: location_status
        运行频率: 每日
*/

select
    snowflake_id,
    location_id,
    warehouse_id,
    location_code,
    location_name,
    location_type,
    capacity,
    capacity_unit,
    current_usage,
    location_status,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_storage_location') }}

{% endsnapshot %}
