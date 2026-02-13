{% snapshot snap_product_recall %}

{{
    config(
        target_schema='snapshots',
        unique_key='recall_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['staging', 'pv', 'safety', 'audit'],
        
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
        }
    )
}}

/*
    Snapshot: snap_product_recall
        Description: PV产品召回快照
        
        业务场景:
        - 召回状态变更追踪
        - 召回历史记录
        - 审计追踪
        
        追踪字段: recall_status
        运行频率: 每日
*/

select
    snowflake_id,
    recall_id,
    recall_code,
    recall_level,
    recall_reason,
    recall_scope,
    product_id,
    batch_numbers,
    recall_date,
    notification_date,
    recall_quantity,
    recall_unit,
    actual_return_quantity,
    recall_status,
    responsible,
    regulatory_report_date,
    close_date,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_product_recall') }}

{% endsnapshot %}
