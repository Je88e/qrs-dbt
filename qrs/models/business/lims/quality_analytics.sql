{{
    config(
        materialized='table',
        tags=['lims', 'quality', 'analytics', 'pqr']
    )
}}

/*
 * 质量分析模型
 * 数据来源: LIMS系统业务模型
 * 业务描述: 基于检验申请数据分析质量管理指标，用于PQR报告
 * 模型类型: 聚合分析模型
 */

with inspection_request_base as (
    select
        request_id,
        material_id,
        material_name,
        sample_type,
        inspection_type,
        priority,
        request_status,
        request_date,
        planned_completion_date,
        actual_completion_date,
        days_overdue
    from {{ ref('inspection_request') }}
),

inspection_enriched as (
    select
        request_id,
        material_id,
        material_name,
        sample_type,
        inspection_type,
        priority,
        request_status,
        request_date,
        planned_completion_date,
        actual_completion_date,
        days_overdue,
        -- 计算处理时长
        case
            when actual_completion_date is not null then
                {{ date_diff_days('actual_completion_date', 'request_date') }}
            else null
        end as actual_processing_days,
        -- 是否按时完成
        case 
            when request_status = '已完成' and (days_overdue is null or days_overdue <= 0) then true
            when request_status = '已完成' and days_overdue > 0 then false
            else null
        end as is_on_time,
        -- 优先级权重
        case 
            when priority = '高' then 3
            when priority = '中' then 2
            when priority = '低' then 1
            else 0
        end as priority_weight
    from inspection_request_base
),

inspection_summary as (
    select
        material_id,
        material_name,
        sample_type,
        inspection_type,
        count(*) as total_requests,
        count(case when request_status = '已完成' then 1 end) as completed_requests,
        count(case when is_on_time = true then 1 end) as on_time_requests,
        avg(actual_processing_days) as avg_processing_days,
        avg(priority_weight) as avg_priority_weight
    from inspection_enriched
    group by material_id, material_name, sample_type, inspection_type
),

final as (
    select
        material_id,
        material_name,
        sample_type,
        inspection_type,
        total_requests,
        completed_requests,
        on_time_requests,
        -- 完成率
        case 
            when total_requests > 0 then 
                round(completed_requests * 100.0 / total_requests, 2)
            else 0 
        end as completion_rate,
        -- 按时完成率
        case 
            when completed_requests > 0 then 
                round(on_time_requests * 100.0 / completed_requests, 2)
            else 0 
        end as on_time_rate,
        round(avg_processing_days, 1) as avg_processing_days,
        round(avg_priority_weight, 1) as avg_priority_weight
    from inspection_summary
)

select * from final

