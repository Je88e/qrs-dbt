{% snapshot snap_deviations %}

{{
    config(
        target_schema='snapshots',
        unique_key='deviation_id',
        strategy='timestamp',
        updated_at='discovery_date',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['snapshot', 'qms', 'audit', 'compliance', 'quality'],

        snapshot_meta_column_names={
            'dbt_valid_from': 'valid_from',
            'dbt_valid_to': 'valid_to',
            'dbt_scd_id': 'snapshot_id',
            'dbt_updated_at': 'last_updated_at',
            'dbt_is_deleted': 'is_deleted'
        }
    )
}}

/*
    Snapshot: snap_deviations
    Description: 偏差管理状态变更快照 - 质量事件追踪
    
    业务场景:
    - 偏差调查进度追踪
    - 根本原因分析时效
    - CAPA 关联追踪
    
    追踪字段: deviation_status, close_date
    运行频率: 每日
*/

select
    -- 主键
    deviation_id,
    
    -- 偏差信息
    deviation_code,
    deviation_title,
    deviation_type,
    deviation_category,
    
    -- 产品和批次
    product_id,
    batch_number,
    
    -- 时间信息
    occurrence_date,
    discovery_date,
    
    -- 偏差描述
    deviation_description,
    immediate_action,
    root_cause,
    corrective_action,
    preventive_action,
    
    -- 状态（核心追踪字段）
    deviation_status,
    
    -- 责任人信息
    investigator,
    reviewer,
    approver,
    
    -- 关闭日期
    close_date,
    
    -- 审计字段
    create_date
    
from {{ ref('stg_deviation') }}

{% endsnapshot %}

