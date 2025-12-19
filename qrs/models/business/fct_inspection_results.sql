{{
    config(
        materialized='view',
        tags=['lims', 'quality', 'inspection', 'pqr']
    )
}}

/*
    Model: fct_inspection_results
    Description: 记录检验结果详细信息，用于质量分析
*/

with inspection_result as (
    select * from {{ ref('stg_inspection_result') }}
),

inspection_task as (
    select * from {{ ref('stg_inspection_task') }}
),

sample as (
    select * from {{ ref('stg_sample') }}
),

test_item as (
    select * from {{ ref('stg_test_item') }}
)

select
    -- 结果主键
    ir.result_id,
    
    -- 关联任务
    ir.task_id,
    
    -- 检验项目
    ir.test_item_id,
    ti.item_code,
    ti.item_name,
    ti.test_method,
    
    -- 样品信息
    ir.sample_id,
    s.sample_code,
    s.batch_number,
    
    -- 检验结果
    ir.test_value,
    ir.test_unit,
    ir.standard_min,
    ir.standard_max,
    ir.result_status,
    
    -- 检验时间
    ir.test_date,
    
    -- 分析员
    ir.analyst_id,
    
    -- 审核信息
    ir.reviewer_id,
    ir.review_date,
    ir.review_status,
    
    -- 备注
    ir.remark,
    
    -- 审计字段
    ir.create_date

from inspection_result ir
left join inspection_task it on ir.task_id = it.task_id
left join sample s on ir.sample_id = s.sample_id
left join test_item ti on ir.test_item_id = ti.test_item_id

