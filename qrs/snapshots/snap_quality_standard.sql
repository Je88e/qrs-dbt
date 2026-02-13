{% snapshot snap_quality_standard %}

{{
    config(
        target_schema='snapshots',
        unique_key='standard_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['staging', 'lims', 'master_data', 'audit'],
        
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
        }
    )
}}

/*
    Snapshot: snap_quality_standard
        Description: LIMS质量标准主数据快照
        
        业务场景:
        - 质量标准变更追踪
        - 标准版本历史记录
        - 审计追踪
        
        追踪字段: standard_status
        运行频率: 每日
*/

select
    snowflake_id,
    standard_id,
    standard_code,
    standard_name,
    material_type,
    standard_version,
    effective_date,
    expiry_date,
    standard_status,
    creator,
    approver,
    approval_date,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_quality_standard') }}

{% endsnapshot %}
