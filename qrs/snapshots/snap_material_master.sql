{% snapshot snap_material_master %}

{{
    config(
        target_schema='snapshots',
        unique_key='material_id',
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
    Snapshot: snap_material_master
        Description: ERP物料主数据快照
        
        业务场景:
        - 物料信息变更追踪
        - 物料规格历史记录
        - 审计追踪
        
        追踪字段: material_status
        运行频率: 每日
*/

select
    snowflake_id,
    material_id,
    material_name,
    material_type,
    material_specification,
    unit,
    supplier_id,
    approval_status,
    is_deleted,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_material_master') }}

{% endsnapshot %}
