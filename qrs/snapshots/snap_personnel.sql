{% snapshot snap_personnel %}

{{
    config(
        target_schema='snapshots',
        unique_key='personnel_id',
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
    Snapshot: snap_personnel
        Description: MES人员主数据快照
        
        业务场景:
        - 人员信息变更追踪
        - 人员状态历史记录
        - 审计追踪
        
        追踪字段: personnel_status
        运行频率: 每日
*/

select
    snowflake_id,
    personnel_id,
    personnel_code,
    personnel_name,
    department,
    job_position,
    skill_level,
    certification,
    workshop_id,
    line_id,
    personnel_status,
    entry_date,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_personnel') }}

{% endsnapshot %}
