{{
    config(
        materialized='view',
        tags=['mes', 'production', 'master_data', 'pqr']
    )
}}

/*
 * 人员信息业务模型
 * 数据来源: MES系统
 * 业务描述: 提供生产人员主数据信息
 */

with personnel as (
    select * from {{ ref('mes_personnel') }}
),

workshop as (
    select * from {{ ref('mes_workshop') }}
),

production_line as (
    select * from {{ ref('mes_production_line') }}
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

