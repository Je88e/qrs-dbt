{% snapshot snap_inspection_tasks %}

{{
    config(
        target_schema='snapshots',
        unique_key='task_id',
        strategy='timestamp',
        updated_at='create_date',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['snapshot', 'lims', 'audit', 'quality', 'high_frequency'],
        
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
    Snapshot: snap_inspection_tasks
    Description: 检验任务状态变更快照 - 任务执行追踪
    
    业务场景:
    - 检验任务执行进度追踪
    - 分析师工作负载分析
    - 任务延期预警
    
    追踪字段: task_status
    运行频率: 每 4 小时（高频）
*/

select
    -- 主键
    task_id,
    
    -- 关联申请
    request_id,
    
    -- 样品和检验项
    sample_id,
    test_item_id,
    
    -- 任务分配信息
    assigned_analyst,
    assigned_date,
    
    -- 计划和完成时间
    planned_completion,
    actual_completion,
    
    -- 状态（核心追踪字段）
    task_status,
    priority,
    
    -- 设备信息
    equipment_id,
    
    -- 审计字段
    create_date
    
from {{ ref('stg_inspection_task') }}

{% endsnapshot %}

