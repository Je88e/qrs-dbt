{{
    config(
        materialized='view',
        tags=['erp', 'production', 'formula', 'pqr']
    )
}}

/*
 * 配方管理业务模型
 * 数据来源: ERP系统
 * 业务描述: 整合配方主表和明细表，提供完整的配方信息视图
 */

with formula_master as (
    select * from {{ ref('erp_formula_master') }}
),

formula_detail as (
    select * from {{ ref('erp_formula_detail') }}
),

material as (
    select * from {{ ref('erp_material_master') }}
)

select
    -- 配方主键
    fm.formula_id,
    fd.formula_detail_id,
    
    -- 配方信息
    fm.formula_name,
    fm.product_id,
    fm.product_name,
    fm.version as formula_version,
    fm.formula_status,
    fm.effective_date,
    fm.expiry_date,
    
    -- 批量信息
    fm.batch_size,
    fm.batch_unit,
    
    -- 配方明细
    fd.material_id,
    fd.material_name,
    m.material_type,
    fd.quantity as material_quantity,
    fd.unit as material_unit,
    fd.sequence as material_sequence,
    fd.is_critical,
    fd.usage_notes,
    
    -- 审批信息
    fm.creator,
    fm.approver,
    fm.approval_date,
    
    -- 审计字段
    fm.create_date

from formula_master fm
left join formula_detail fd on fm.formula_id = fd.formula_id
left join material m on fd.material_id = m.material_id

