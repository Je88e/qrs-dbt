{{
    config(
        materialized='view',
        tags=['lims', 'quality', 'inspection', 'pqr']
    )
}}

/*
    Model: fct_inspection_requests
    Description: 提供检验申请的完整信息
*/

with inspection_request as (
    select * from {{ ref('stg_inspection_request') }}
),

material as (
    select * from {{ ref('stg_material_master') }}
)

select
    -- 申请主键
    ir.request_id,
    
    -- 物料信息
    ir.material_id,
    m.material_name,
    m.material_type,
    ir.batch_number,
    
    -- 样品信息
    ir.sample_type,
    ir.sample_qty as sample_quantity,
    ir.sample_unit,
    
    -- 申请信息
    ir.request_date,
    ir.requester,
    ir.inspection_type,
    ir.priority,
    
    -- 申请状态
    ir.request_status,
    
    -- 计划和实际完成
    ir.planned_completion_date,
    ir.actual_completion_date,
    
    -- 超期天数计算
    case
        when ir.actual_completion_date is not null and ir.planned_completion_date is not null
        then {{ date_diff_days('ir.actual_completion_date', 'ir.planned_completion_date') }}
        else null
    end as days_overdue

from inspection_request ir
left join material m on ir.material_id = m.material_id

