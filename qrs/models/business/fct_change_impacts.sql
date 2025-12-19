{{
    config(
        materialized='view',
        tags=['qms', 'quality', 'change', 'pqr']
    )
}}

/*
    Model: fct_change_impacts
    Description: 提供变更影响评估的详细信息
*/

with change_impact as (
    select * from {{ ref('stg_change_impact') }}
),

change_control as (
    select * from {{ ref('stg_change_control') }}
)

select
    -- 评估主键
    ci.impact_id,
    
    -- 关联变更
    ci.change_id,
    cc.change_code,
    cc.change_title,
    cc.change_type,
    
    -- 影响评估
    ci.impact_area,
    ci.impact_description,
    ci.impact_level,
    
    -- 影响范围
    ci.affected_documents,
    ci.affected_processes,
    
    -- 风险评估
    ci.risk_assessment,
    ci.mitigation_measures,
    
    -- 评估人员
    ci.assessor,
    ci.assess_date,
    
    -- 审计字段
    ci.create_date

from change_impact ci
left join change_control cc on ci.change_id = cc.change_id

