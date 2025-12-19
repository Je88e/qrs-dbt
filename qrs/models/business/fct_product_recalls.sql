{{
    config(
        materialized='view',
        tags=['pv', 'pharmacovigilance', 'safety', 'pqr']
    )
}}

/*
    Model: fct_product_recalls
    Description: 提供产品召回的完整信息
*/

with product_recall as (
    select * from {{ ref('stg_product_recall') }}
)

select
    -- 召回主键
    recall_id,
    
    -- 召回信息
    recall_code,
    recall_level,
    recall_reason,
    recall_scope,
    
    -- 产品批次
    product_id,
    batch_numbers,
    
    -- 时间信息
    recall_date,
    notification_date,
    
    -- 召回数量
    recall_qty as recall_quantity,
    recall_unit,
    actual_return_qty as actual_return_quantity,
    
    -- 召回率计算
    case 
        when recall_qty > 0 then round(cast(actual_return_qty as decimal) / recall_qty * 100, 2)
        else 0
    end as return_rate_percent,
    
    -- 状态
    status as recall_status,
    
    -- 责任人
    responsible,
    
    -- 监管报告
    regulatory_report_date,
    
    -- 关闭日期
    close_date,
    
    -- 召回周期（天）
    case
        when close_date is not null and recall_date is not null
        then {{ date_diff_days('close_date', 'recall_date') }}
        else null
    end as recall_duration_days,
    
    -- 审计字段
    create_date

from product_recall

