{% snapshot snap_test_item %}

{{
    config(
        target_schema='snapshots',
        unique_key='test_item_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['staging', 'lims', 'master_data', 'audit'],
        
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
        }
    )
}}

/*
    Snapshot: snap_test_item
        Description: LIMS检验项目主数据快照
        
        业务场景:
        - 检验项目信息变更追踪
        - 检验方法历史记录
        - 审计追踪
        
        追踪字段: test_item_status
        运行频率: 每日
*/

select
    snowflake_id,
    test_item_id,
    item_code,
    item_name,
    test_method,
    standard_id,
    min_value,
    max_value,
    unit,
    required_equipment,
    test_duration,
    test_duration_unit,
    item_status,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_test_item') }}

{% endsnapshot %}
