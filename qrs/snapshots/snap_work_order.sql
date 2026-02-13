{% snapshot snap_work_order %}

{{
    config(
        target_schema='snapshots',
        unique_key='work_order_number',
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
    Snapshot: snap_work_order
        Description: MES生产工单快照
        
        业务场景:
        - 工单状态变更追踪
        - 工单历史记录
        - 审计追踪
        
        追踪字段: work_order_status
        运行频率: 每日
*/

select
    snowflake_id,
    work_order_number,
    product_id,
    batch_number,
    planned_quantity,
    actual_quantity,
    unit,
    work_order_status,
    planned_start_date,
    planned_end_date,
    actual_start_date,
    actual_end_date,
    workshop_id,
    create_by,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_work_order') }}

{% endsnapshot %}
