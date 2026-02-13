{% snapshot snap_inspection_result %}

{{
    config(
        target_schema='snapshots',
        unique_key='result_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['staging', 'lims', 'quality', 'audit'],
        
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
        }
    )
}}

/*
    Snapshot: snap_inspection_result
        Description: LIMS检验结果快照
        
        业务场景:
        - 检验结果修正追踪
        - 检验数据历史记录
        - 审计追踪
        
        运行频率: 每日
*/

select
    snowflake_id,
    result_id,
    task_id,
    test_item_id,
    sample_id,
    test_value,
    test_unit,
    standard_min,
    standard_max,
    result_status,
    test_date,
    analyst_id,
    reviewer_id,
    review_date,
    review_status,
    remark,
    create_date,
    update_date,
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_inspection_result') }}

{% endsnapshot %}
