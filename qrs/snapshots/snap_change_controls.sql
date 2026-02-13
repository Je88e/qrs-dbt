{% snapshot snap_change_controls %}

{{
    config(
        target_schema='snapshots',
        unique_key='change_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['snapshot', 'qms', 'audit', 'compliance'],

        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
        }
    )
}}

/*
    Snapshot: snap_change_controls
    Description: 变更控制状态变更快照 - GMP 合规追踪
    
    业务场景:
    - 变更审批流程追踪
    - 变更实施进度监控
    - 法规合规审计
    
    追踪字段: change_status, approval_date
    运行频率: 每日
*/

select
    snowflake_id,
    -- 主键
    change_id,
    
    -- 变更信息
    change_code,
    change_title,
    change_type,
    change_category,
    change_description,
    
    -- 发起信息
    initiator,
    initiate_date,
    priority,
    
    -- 状态（核心追踪字段）
    change_status,
    
    -- 计划和实际完成
    planned_completion,
    actual_completion,
    
    -- 审批信息
    reviewer,
    approver,
    approval_date,
    
    -- 审计字段
    create_date,
    update_date,

    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_change_control') }}

{% endsnapshot %}

