{% snapshot snap_environment_data %}

{{
    config(
        target_schema='snapshots',
        unique_key='data_id',
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
    Snapshot: snap_environment_data
        Description: SCADA环境监测数据快照
        
        业务场景:
        - 环境数据修正追踪
        - 环境异常历史记录
        - 审计追踪
        
        运行频率: 每日
*/

select
    snowflake_id,
    data_id,
    location_code,
    location_name,
    temperature,
    humidity,
    pressure_difference,
    particle_count,
    collection_time,
    monitoring_status,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_environment_data') }}

{% endsnapshot %}
