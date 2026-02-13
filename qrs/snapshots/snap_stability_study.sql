{% snapshot snap_stability_study %}

{{
    config(
        target_schema='snapshots',
        unique_key='study_id',
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
    Snapshot: snap_stability_study
        Description: LIMS稳定性研究快照
        
        业务场景:
        - 稳定性研究状态追踪
        - 研究历史记录
        - 审计追踪
        
        追踪字段: study_status
        运行频率: 每日
*/

select
    snowflake_id,
    study_id,
    study_code,
    product_id,
    batch_number,
    study_type,
    storage_condition,
    timepoint,
    timepoint_months,
    sample_id,
    test_item_id,
    test_item_name,
    test_value,
    test_unit,
    specification,
    result_status,
    test_date,
    analyst_id,
    study_status,
    create_date,
    CAST(COALESCE(loaded_at, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_stability_study') }}

{% endsnapshot %}
