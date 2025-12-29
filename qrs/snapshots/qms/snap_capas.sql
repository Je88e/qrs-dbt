{% snapshot snap_capas %}

{{
    config(
        target_schema='snapshots',
        unique_key='capa_id',
        strategy='timestamp',
        updated_at='create_date',
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
    Snapshot: snap_capas
    Description: CAPA 状态变更快照 - 纠正预防措施追踪
    
    业务场景:
    - CAPA 执行进度追踪
    - 有效性验证追踪
    - 法规合规审计
    
    追踪字段: capa_status, effectiveness_check
    运行频率: 每日
*/

select
    -- 主键
    capa_id,
    
    -- CAPA 信息
    capa_code,
    capa_title,
    capa_type,
    
    -- 来源信息
    source_type,
    source_id,
    
    -- CAPA 描述
    capa_description,
    root_cause_analysis,
    corrective_action,
    preventive_action,
    
    -- 责任人和时间
    responsible,
    planned_completion,
    actual_completion,
    
    -- 状态（核心追踪字段）
    capa_status,
    
    -- 有效性验证
    effectiveness_check,
    effectiveness_date,
    
    -- 审批信息
    creator,
    approver,
    
    -- 审计字段
    create_date
    
from {{ ref('stg_capa') }}

{% endsnapshot %}

