{% snapshot snap_supplier_master %}

{{
    config(
        target_schema='snapshots',
        unique_key='supplier_id',
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
    Snapshot: snap_supplier_master
        Description: ERP供应商主数据快照
        
        业务场景:
        - 供应商信息变更追踪
        - 供应商状态历史记录
        - 审计追踪
        
        追踪字段: supplier_status
        运行频率: 每日
*/

select
    snowflake_id,
    supplier_id,
    supplier_name,
    supplier_type,
    contact_person,
    contact_phone,
    address,
    qualification_status,
    audit_date,
    audit_score,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_supplier_master') }}

{% endsnapshot %}
