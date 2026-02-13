{% snapshot snap_material_consumption %}

{{
    config(
        target_schema='snapshots',
        unique_key='consumption_id',
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
    Snapshot: snap_material_consumption
        Description: MES物料消耗记录快照
        
        业务场景:
        - 物料消耗数据修正追踪
        - 消耗历史记录
        - 审计追踪
        
        运行频率: 每日
*/

select
    snowflake_id,
    consumption_id,
    work_order_number,
    operation_id,
    material_id,
    batch_number,
    planned_quantity,
    actual_quantity,
    unit,
    consumption_date,
    operator_id,
    variance_reason,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_material_consumption') }}

{% endsnapshot %}
