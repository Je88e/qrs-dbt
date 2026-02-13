{% snapshot snap_workshop %}

{{
    config(
        target_schema='snapshots',
        unique_key='workshop_id',
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
    Snapshot: snap_workshop
        Description: MES车间主数据快照
        
        业务场景:
        - 车间信息变更追踪
        - 车间状态历史记录
        - 审计追踪
        
        追踪字段: workshop_status
        运行频率: 每日
*/

select
    snowflake_id,
    workshop_id,
    workshop_code,
    workshop_name,
    workshop_type,
    workshop_area,
    clean_level,
    workshop_manager,
    workshop_status,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_workshop') }}

{% endsnapshot %}
