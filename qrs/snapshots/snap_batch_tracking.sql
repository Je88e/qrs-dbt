{% snapshot snap_batch_tracking %}

{{
    config(
        target_schema='snapshots',
        unique_key='tracking_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['staging', 'scada', 'production', 'audit'],
        
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
        }
    )
}}

/*
    Snapshot: snap_batch_tracking
        Description: SCADA批次追踪记录快照
        
        业务场景:
        - 批次生产状态变更追踪
        - 生产进度监控
        - 审计追踪
        
        追踪字段: tracking_status
        运行频率: 每小时
*/

select
    snowflake_id,
    tracking_id,
    batch_number,
    work_order_number,
    product_id,
    operation_id,
    equipment_id,
    start_time,
    end_time,
    tracking_status,
    operator_id,
    yield_quantity,
    unit,
    quality_status,
    remark,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_batch_tracking') }}

{% endsnapshot %}
