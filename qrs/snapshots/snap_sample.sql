{% snapshot snap_sample %}

{{
    config(
        target_schema='snapshots',
        unique_key='sample_id',
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
    Snapshot: snap_sample
        Description: LIMS样品主数据快照
        
        业务场景:
        - 样品状态变更追踪
        - 样品历史记录
        - 审计追踪
        
        追踪字段: sample_status
        运行频率: 每日
*/

select
    snowflake_id,
    sample_id,
    sample_code,
    sample_type,
    sample_quantity,
    sample_unit,
    material_id, 
    batch_number,
    sample_date,
    sampler,
    storage_condition,
    storage_location,
    expiry_date,
    sample_status,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_sample') }}

{% endsnapshot %}
