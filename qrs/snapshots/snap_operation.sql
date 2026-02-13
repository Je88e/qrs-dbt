{% snapshot snap_operation %}

{{
    config(
        target_schema='snapshots',
        unique_key='operation_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['staging', 'mes', 'production', 'audit'],
        
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
        }
    )
}}

/*
    Snapshot: snap_operation
        Description: MES工序主数据快照
        
        业务场景:
        - 工序信息变更追踪
        - 工艺路线历史记录
        - 审计追踪
        
        追踪字段: operation_status
        运行频率: 每日
*/

select
    snowflake_id,
    operation_id,
    operation_code,
    operation_name,
    operation_type,
    standard_duration,
    duration_unit,
    equipment_type,
    skill_requirement,
    sop_document,
    operation_status,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_operation') }}

{% endsnapshot %}
