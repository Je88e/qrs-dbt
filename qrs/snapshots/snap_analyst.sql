{% snapshot snap_analyst %}

{{
    config(
        target_schema='snapshots',
        unique_key='analyst_id',
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
    Snapshot: snap_analyst
        Description: LIMS分析员主数据快照
        
        业务场景:
        - 分析员资格变更追踪
        - 证书有效期监控
        - 审计追踪
        
        追踪字段: analyst_status
        运行频率: 每日
*/

select
    snowflake_id,
    analyst_id,
    analyst_code,
    analyst_name,
    department,
    qualification,
    certification_date,
    certification_expiry,
    analyst_status,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_analyst') }}

{% endsnapshot %}
