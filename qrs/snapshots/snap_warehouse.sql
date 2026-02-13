{% snapshot snap_warehouse %}

{{
    config(
        target_schema='snapshots',
        unique_key='warehouse_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['staging', 'erp', 'master_data', 'audit'],
        
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
        }
    )
}}

/*
    Snapshot: snap_warehouse
        Description: ERP仓库主数据快照
        
        业务场景:
        - 仓库信息变更追踪
        - 仓库状态历史记录
        - 审计追踪
        
        追踪字段: warehouse_status
        运行频率: 每日
*/

select
    snowflake_id,
    warehouse_id,
    warehouse_name,
    warehouse_type,
    address,
    warehouse_area,
    manager,
    contact_phone,
    warehouse_status,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_warehouse') }}

{% endsnapshot %}
