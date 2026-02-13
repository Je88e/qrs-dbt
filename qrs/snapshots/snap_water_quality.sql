{% snapshot snap_water_quality %}

{{
    config(
        target_schema='snapshots',
        unique_key='test_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['staging', 'lims', 'quality', 'audit'],
        
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
        }
    )
}}

/*
    Snapshot: snap_water_quality
        Description: LIMS水质监测快照
        
        业务场景:
        - 水质监测数据修正追踪
        - 水质历史记录
        - 审计追踪
        
        运行频率: 每日
*/

select
    snowflake_id, 
    test_id, 
    monitoring_point_id,
    monitoring_point_name,
    water_type, 
    parameter_name,
    test_value,
    test_unit,
    limit_min,
    limit_max,
    result_status, 
    analyst_id,
    equipment_id,
    batch_number,test_date,
    create_date,
    CAST(COALESCE(loaded_at, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_water_quality') }}

{% endsnapshot %}
