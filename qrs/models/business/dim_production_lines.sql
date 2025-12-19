{{
    config(
        materialized='view',
        tags=['mes', 'production', 'master_data', 'pqr']
    )
}}

/*
    Model: dim_production_lines
    Description: 提供产线主数据信息，关联车间
*/

with production_line as (
    select * from {{ ref('stg_production_line') }}
),

workshop as (
    select * from {{ ref('stg_workshop') }}
)

select
    -- 产线主键
    pl.line_id,
    
    -- 产线信息
    pl.line_code,
    pl.line_name,
    pl.product_type,
    
    -- 产能信息
    pl.capacity,
    pl.capacity_unit,
    
    -- 产线状态
    pl.status as line_status,
    
    -- 管理信息
    pl.manager as line_manager,
    
    -- 车间信息
    pl.workshop_id,
    ws.workshop_name,
    ws.workshop_type,
    ws.clean_level,
    
    -- 审计字段
    pl.create_date

from production_line pl
left join workshop ws on pl.workshop_id = ws.workshop_id

