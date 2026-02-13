{% snapshot snap_work_order_operation %}

{{
    config(
        target_schema='snapshots',
        unique_key='work_order_operation_id',
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
    Snapshot: snap_work_order_operation
        Description: MES工单工序记录快照
        
        业务场景:
        - 工序执行状态变更追踪
        - 工序历史记录
        - 审计追踪
        
        追踪字段: operation_status
        运行频率: 每日
*/

select
    snowflake_id,
    work_order_operation_id,
    work_order_number,
    operation_id,
    operation_sequence,
    planned_start,
    planned_end,
    actual_start,
    actual_end,
    operation_status,
    equipment_id,
    operator_id,
    yield_quantity,
    defect_quantity,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_work_order_operation') }}

{% endsnapshot %}
