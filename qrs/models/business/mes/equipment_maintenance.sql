{{
    config(
        materialized='view',
        tags=['mes', 'equipment', 'maintenance', 'pqr']
    )
}}

/*
 * 设备维护业务模型
 * 数据来源: MES系统
 * 业务描述: 记录设备维护信息，用于设备管理和预防性维护分析
 */

with equipment_maintenance as (
    select * from {{ ref('mes_equipment_maintenance') }}
),

equipment as (
    select * from {{ ref('mes_equipment') }}
)

select
    -- 维护主键
    em.maintenance_id,
    
    -- 设备信息
    em.equipment_id,
    eq.equipment_code,
    eq.equipment_name,
    eq.equipment_type,
    eq.workshop_id,
    eq.line_id,
    
    -- 维护信息
    em.maintenance_type,
    em.maintenance_date,
    em.maintenance_content,
    em.maintenance_result,
    em.downtime_hours,
    
    -- 维护人员
    em.technician,
    
    -- 审核信息
    em.reviewer,
    em.review_status,
    
    -- 下次维护计划
    em.next_maintenance_date,
    
    -- 审计字段
    em.create_date

from equipment_maintenance em
left join equipment eq on em.equipment_id = eq.equipment_id

