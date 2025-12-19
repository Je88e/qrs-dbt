{{
    config(
        materialized='view',
        tags=['mes', 'production', 'master_data', 'pqr']
    )
}}

/*
    Model: dim_personnel
    Description: 提供生产人员主数据信息
*/

with personnel as (
    select * from {{ ref('stg_personnel') }}
),

workshop as (
    select * from {{ ref('stg_workshop') }}
),

production_line as (
    select * from {{ ref('stg_production_line') }}
)

select
    -- 人员主键
    per.personnel_id,
    
    -- 人员信息
    per.personnel_code,
    per.personnel_name,
    per.department,
    per.position,
    per.skill_level,
    per.certification,
    
    -- 工作分配
    per.workshop_id,
    ws.workshop_name,
    per.line_id,
    pl.line_name,
    
    -- 人员状态
    per.status as personnel_status,
    per.entry_date,
    
    -- 审计字段
    per.create_date

from personnel per
left join workshop ws on per.workshop_id = ws.workshop_id
left join production_line pl on per.line_id = pl.line_id

