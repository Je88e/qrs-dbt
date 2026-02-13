{% snapshot snap_inspection_tasks %}

{{
    config(
        target_schema='snapshots',
        unique_key='task_id',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        tags=['snapshot', 'lims', 'audit', 'quality', 'high_frequency'],
        
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id', 
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
    snowflake_id,
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
    create_date,
    update_date,
    -- 处理 NULL 值：如果 update_date 为 NULL，使用 create_date
    CAST(COALESCE(loaded_at, update_date, create_date) AT TIME ZONE 'Asia/Shanghai' AS timestamptz) as loaded_at

from {{ ref('stg_inspection_task') }}

{% endsnapshot %}

