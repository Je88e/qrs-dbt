{{
    config(
        materialized='view',
        tags=['lims', 'quality', 'standard', 'pqr']
    )
}}

/*
    Model: dim_quality_standards
    Description: 提供质量标准主数据信息
*/

with quality_standard as (
    select * from {{ ref('stg_quality_standard') }}
)

select
    -- 标准主键
    standard_id,
    
    -- 标准信息
    standard_code,
    standard_name,
    material_type,
    version as standard_version,
    
    -- 有效期
    effective_date,
    expiry_date,
    status as standard_status,
    
    -- 创建和审批
    creator,
    approver,
    approval_date,
    
    -- 有效期剩余天数
    case
        when expiry_date is not null
        then {{ date_diff_days('expiry_date', 'current_date') }}
        else null
    end as days_until_expiry,
    
    -- 审计字段
    create_date

from quality_standard

