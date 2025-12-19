{{
    config(
        materialized='view',
        tags=['lims', 'quality', 'inspection', 'pqr']
    )
}}

/*
    Model: fct_inspection_tasks
    Description: 提供检验任务的执行信息
*/

with inspection_task as (
    select * from {{ ref('stg_inspection_task') }}
),

inspection_request as (
    select * from {{ ref('stg_inspection_request') }}
),

sample as (
    select * from {{ ref('stg_sample') }}
),

test_item as (
    select * from {{ ref('stg_test_item') }}
),

analyst as (
    select * from {{ ref('stg_analyst') }}
)

select
    -- 任务主键
    it.task_id,
    
    -- 关联申请
    it.request_id,
    ir.inspection_type,
    
    -- 样品信息
    it.sample_id,
    s.sample_code,
    s.sample_type,
    s.batch_number,
    
    -- 检验项目
    it.test_item_id,
    ti.item_code,
    ti.item_name,
    ti.test_method,
    
    -- 分析员
    it.assigned_analyst,
    a.analyst_name,
    a.qualification,
    
    -- 时间信息
    it.assigned_date,
    it.planned_completion,
    it.actual_completion,
    
    -- 任务状态
    it.task_status,
    it.priority,
    
    -- 设备
    it.equipment_id,
    
    -- 审计字段
    it.create_date

from inspection_task it
left join inspection_request ir on it.request_id = ir.request_id
left join sample s on it.sample_id = s.sample_id
left join test_item ti on it.test_item_id = ti.test_item_id
left join analyst a on it.assigned_analyst = a.analyst_id

