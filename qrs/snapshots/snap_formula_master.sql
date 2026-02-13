{% snapshot snap_formula_master %}

{{
    config(
        target_schema='snapshots',
        unique_key='formula_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['staging', 'erp', 'production', 'audit'],
        
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
        }
    )
}}

/*
    Snapshot: snap_formula_master
        Description: ERP配方主数据快照
        
        业务场景:
        - 配方信息变更追踪
        - 配方版本历史记录
        - 审计追踪
        
        追踪字段: formula_status
        运行频率: 每日
*/

select
    snowflake_id,
    formula_id,
    formula_name,
    product_id,
    product_name,
    formula_version,
    formula_status,
    effective_date,
    expiry_date,
    batch_size,
    batch_unit,
    creator,
    approver,
    approval_date,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_formula_master') }}

{% endsnapshot %}
