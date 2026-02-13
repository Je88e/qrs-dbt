{% snapshot snap_validation_record %}

{{
    config(
        target_schema='snapshots',
        unique_key='validation_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['staging', 'qms', 'quality', 'audit'],
        
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
        }
    )
}}

/*
    Snapshot: snap_validation_record
        Description: QMS验证记录快照
        
        业务场景:
        - 验证状态变更追踪
        - 验证历史记录
        - 审计追踪
        
        追踪字段: validation_status
        运行频率: 每日
*/

select
    snowflake_id,
        validation_id,
        validation_code,
        validation_type,
        validation_title,
        protocol_no,
        product_id,
        equipment_id,
        batch_numbers,
        start_date,
        end_date,
        validation_result,
        deviation_count,
        responsible,
        reviewer,
        approver,
        approval_date,
        next_revalidation_date,
        validation_status,
        create_date,
    CAST(COALESCE(loaded_at, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_validation_record') }}

{% endsnapshot %}
