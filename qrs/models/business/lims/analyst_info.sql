{{
    config(
        materialized='view',
        tags=['lims', 'quality', 'master_data', 'pqr']
    )
}}

/*
 * 分析员信息业务模型
 * 数据来源: LIMS系统
 * 业务描述: 提供分析员主数据信息
 */

with analyst as (
    select * from {{ ref('lims_analyst') }}
)

select
    -- 分析员主键
    analyst_id,
    
    -- 分析员信息
    analyst_code,
    analyst_name,
    department,
    qualification,
    skill_level,
    
    -- 认证信息
    certification_date,
    certification_expiry,
    
    -- 主管信息
    supervisor_id,
    
    -- 状态
    status as analyst_status,
    
    -- 认证剩余天数
    case
        when certification_expiry is not null
        then {{ date_diff_days('certification_expiry', 'current_date') }}
        else null
    end as days_until_cert_expiry,
    
    -- 审计字段
    create_date

from analyst

