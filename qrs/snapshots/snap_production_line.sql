{% snapshot snap_production_line %}

{{
    config(
        target_schema='snapshots',
        unique_key='line_id',
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
    Snapshot: snap_production_line
        Description: MES生产线主数据快照
        
        业务场景:
        - 生产线信息变更追踪
        - 生产线状态历史记录
        - 审计追踪
        
        追踪字段: line_status
        运行频率: 每日
*/

select
    snowflake_id,
    line_id,
    line_code,
    line_name,
    workshop_id,
    product_type,
    capacity,
    capacity_unit,
    line_status,
    line_manager,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_production_line') }}

{% endsnapshot %}
