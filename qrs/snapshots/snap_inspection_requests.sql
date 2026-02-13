{% snapshot snap_inspection_requests %}

{{
    config(
        target_schema='snapshots',
        unique_key='request_id',
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
    Snapshot: snap_inspection_requests
    Description: 检验申请状态变更快照 - 高频更新追踪
    
    业务场景:
    - 检验申请处理流程追踪
    - 检验时效性分析
    - 实验室工作负载监控
    
    追踪字段: request_status
    运行频率: 每 4 小时（高频）
*/

select
    snowflake_id,
    -- 主键
    request_id,
    
    -- 物料和批次信息
    material_id,
    batch_number,
    sample_type,
    
    -- 申请信息
    request_date,
    requester,
    inspection_type,
    priority,
    
    -- 状态（核心追踪字段）
    request_status,
    
    -- 计划和完成时间
    planned_completion_date,
    actual_completion_date,
    
    -- 样品信息
    sample_quantity,
    sample_unit,
 
    loaded_at

from {{ ref('stg_inspection_request') }}

{% endsnapshot %}

