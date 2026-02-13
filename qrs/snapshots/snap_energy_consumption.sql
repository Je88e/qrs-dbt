{% snapshot snap_energy_consumption %}

{{
    config(
        target_schema='snapshots',
        unique_key='energy_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['staging', 'scada', 'monitoring', 'audit'],
        
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
        }
    )
}}

/*
    Snapshot: snap_energy_consumption
        Description: SCADA能耗记录快照
        
        业务场景:
        - 能耗数据修正追踪
        - 能耗分析历史记录
        - 审计追踪
        
        运行频率: 每日
*/

select
    snowflake_id,
    energy_id,
    equipment_id,
    workshop_id,
    energy_type,
    consumption_value,
    unit,
    collection_date,
    collection_hour,
    work_order_number,
    batch_number,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_energy_consumption') }}

{% endsnapshot %}
