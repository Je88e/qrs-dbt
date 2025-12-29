{{
    config(
        materialized='view',
        tags=['qms', 'quality', 'change', 'pqr']
    )
}}

/*
    Model: fct_change_controls
    Description: 提供变更控制的完整信息
*/

with change_control as (
    select * from {{ ref('stg_change_control') }}
)

select
    -- 变更主键
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
    
    -- 变更状态
    change_status,
    
    -- 计划和实际完成
    planned_completion,
    actual_completion,
    
    -- 审批信息
    reviewer,
    approver,
    approval_date,
    
    -- 超期天数计算
    case
        when actual_completion is not null and planned_completion is not null
        then {{ date_diff_days('actual_completion', 'planned_completion') }}
        else null
    end as days_overdue,
    
    -- 审计字段
    create_date

from change_control

