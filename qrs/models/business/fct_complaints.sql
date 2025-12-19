{{
    config(
        materialized='view',
        tags=['pv', 'pharmacovigilance', 'quality', 'pqr']
    )
}}

/*
    Model: fct_complaints
    Description: 提供产品投诉处理的完整信息
*/

with complaint as (
    select * from {{ ref('stg_complaint') }}
)

select
    -- 投诉主键
    complaint_id,
    
    -- 投诉信息
    complaint_code,
    complaint_type,
    complaint_source,
    
    -- 产品批次
    product_id,
    batch_number,
    
    -- 时间信息
    complaint_date,
    receive_date,
    
    -- 投诉内容
    complaint_description,
    
    -- 联系人信息
    contact_name,
    contact_phone,
    
    -- 优先级和状态
    priority,
    status as complaint_status,
    
    -- 调查信息
    investigator,
    investigation_result,
    corrective_action,
    
    -- 响应和关闭时间
    response_date,
    close_date,
    
    -- 响应时间（天）
    case
        when response_date is not null and receive_date is not null
        then {{ date_diff_days('response_date', 'receive_date') }}
        else null
    end as response_days,

    -- 处理周期（天）
    case
        when close_date is not null and receive_date is not null
        then {{ date_diff_days('close_date', 'receive_date') }}
        else null
    end as processing_days,
    
    -- 审计字段
    create_date

from complaint

