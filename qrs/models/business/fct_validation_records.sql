{{
    config(
        materialized='view',
        tags=['qms', 'validation', 'gxp', 'pqr']
    )
}}

/*
    Model: fct_validation_records
    Description: 验证记录 - 提供验证活动的完整信息和状态跟踪
*/

with validation_record as (
    select * from {{ ref('stg_validation_record') }}
),

equipment as (
    select * from {{ ref('stg_equipment') }}
)

select
    -- 主键
    vr.validation_id,
    vr.validation_code,

    -- 验证信息
    vr.validation_type,
    vr.validation_title,
    vr.protocol_no,

    -- 关联信息
    vr.product_id,
    vr.equipment_id,
    e.equipment_code,
    e.equipment_name,
    vr.batch_numbers,

    -- 日期信息
    vr.start_date,
    vr.end_date,
    case
        when vr.end_date is not null and vr.start_date is not null
        then vr.end_date - vr.start_date
        else null
    end as validation_duration_days,

    -- 验证结果
    vr.validation_result,
    vr.deviation_count,
    case
        when vr.validation_result = '通过' then true
        when vr.validation_result in ('有条件通过', '未通过') then false
        else null
    end as is_passed,

    -- 审批流程
    vr.responsible,
    vr.reviewer,
    vr.approver,
    vr.approval_date,

    -- 再验证
    vr.next_revalidation_date,
    case
        when vr.next_revalidation_date < current_date then true
        else false
    end as is_revalidation_overdue,
    vr.next_revalidation_date - current_date as days_until_revalidation,

    -- 状态
    vr.validation_status,

    -- 审计字段
    vr.create_date

from validation_record vr
left join equipment e on vr.equipment_id = e.equipment_id
