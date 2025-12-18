{{
    config(
        materialized='view',
        tags=['pv', 'pharmacovigilance', 'safety', 'pqr']
    )
}}

/*
 * 不良反应业务模型
 * 数据来源: 药物警戒系统
 * 业务描述: 提供药物不良反应报告的完整信息
 */

with adverse_event as (
    select * from {{ ref('pv_adverse_event') }}
)

select
    -- 事件主键
    event_id,
    
    -- 事件信息
    event_code,
    event_type,
    severity,
    
    -- 产品批次
    product_id,
    batch_number,
    
    -- 时间信息
    event_date,
    report_date,
    
    -- 事件描述
    description as event_description,
    
    -- 患者信息
    patient_age,
    patient_gender,
    outcome,
    
    -- 因果关系评估
    causality_assessment,
    
    -- 报告人信息
    reporter_type,
    reporter_name,
    
    -- 状态
    status as event_status,
    
    -- 调查信息
    investigator,
    close_date,
    
    -- 处理周期（天）
    case
        when close_date is not null and report_date is not null
        then {{ date_diff_days('close_date', 'report_date') }}
        else null
    end as processing_days,
    
    -- 审计字段
    create_date

from adverse_event

