{{
    config(
        materialized='view',
        tags=['qms', 'quality', 'capa', 'pqr']
    )
}}

/*
 * CAPA管理业务模型
 * 数据来源: QMS系统
 * 业务描述: 提供纠正预防措施(CAPA)的完整信息
 */

with capa as (
    select * from {{ ref('qms_capa') }}
),

deviation as (
    select * from {{ ref('qms_deviation') }}
)

select
    -- CAPA主键
    c.capa_id,
    
    -- CAPA信息
    c.capa_code,
    c.capa_title,
    c.capa_type,
    
    -- 来源信息
    c.source_type,
    c.source_id,
    case 
        when c.source_type = '偏差' then d.deviation_code
        else null
    end as source_code,
    
    -- CAPA内容
    c.description as capa_description,
    c.root_cause_analysis,
    c.corrective_action,
    c.preventive_action,
    
    -- 责任和时间
    c.responsible,
    c.planned_completion,
    c.actual_completion,
    
    -- CAPA状态
    c.status as capa_status,
    
    -- 有效性检查
    c.effectiveness_check,
    c.effectiveness_date,
    
    -- 创建和审批
    c.creator,
    c.approver,
    
    -- 完成周期（天）
    case
        when c.actual_completion is not null and c.create_date is not null
        then {{ date_diff_days('c.actual_completion', 'c.create_date') }}
        else null
    end as completion_days,
    
    -- 审计字段
    c.create_date

from capa c
left join deviation d on c.source_id = d.deviation_id and c.source_type = '偏差'

