{{
    config(
        materialized='view',
        tags=['qms', 'quality', 'change', 'pqr']
    )
}}

/*
    Model: fct_change_implementations
    Description: 提供变更实施任务的执行信息
*/

with change_implementation as (
    select * from {{ ref('stg_change_implementation') }}
),

change_control as (
    select * from {{ ref('stg_change_control') }}
)

select
    -- 实施主键
    ci.implementation_id,
    
    -- 关联变更
    ci.change_id,
    cc.change_code,
    cc.change_title,
    
    -- 任务信息
    ci.task_name,
    ci.task_description,
    ci.responsible,
    
    -- 时间信息
    ci.planned_start,
    ci.planned_end,
    ci.actual_start,
    ci.actual_end,
    
    -- 任务状态
    ci.task_status,
    
    -- 完成证据
    ci.completion_evidence,
    
    -- 审核信息
    ci.reviewer,
    ci.review_date,
    
    -- 超期天数计算
    case
        when ci.actual_end is not null and ci.planned_end is not null
        then {{ date_diff_days('ci.actual_end', 'ci.planned_end') }}
        else null
    end as days_overdue,
    
    -- 审计字段
    ci.create_date

from change_implementation ci
left join change_control cc on ci.change_id = cc.change_id

