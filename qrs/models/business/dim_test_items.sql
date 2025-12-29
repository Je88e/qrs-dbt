{{
    config(
        materialized='view',
        tags=['lims', 'quality', 'standard', 'pqr']
    )
}}

/*
    Model: dim_test_items
    Description: 提供检验项目主数据信息
*/

with test_item as (
    select * from {{ ref('stg_test_item') }}
),

quality_standard as (
    select * from {{ ref('stg_quality_standard') }}
)

select
    -- 项目主键
    ti.test_item_id,
    
    -- 项目信息
    ti.item_code,
    ti.item_name,
    ti.test_method,
    
    -- 关联标准
    ti.standard_id,
    qs.standard_code,
    qs.standard_name,
    
    -- 限度要求
    ti.min_value,
    ti.max_value,
    ti.unit,
    
    -- 检验要求
    ti.required_equipment,
    ti.test_duration,
    ti.test_duration_unit,
    
    -- 项目状态
    ti.item_status,
    
    -- 审计字段
    ti.create_date

from test_item ti
left join quality_standard qs on ti.standard_id = qs.standard_id

