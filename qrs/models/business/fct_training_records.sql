{{
    config(
        materialized='view',
        tags=['qms', 'training', 'personnel', 'pqr']
    )
}}

/*
    Model: fct_training_records
    Description: 培训记录 - 提供人员培训活动的完整信息
*/

with training_record as (
    select * from {{ ref('stg_training_record') }}
),

personnel as (
    select * from {{ ref('stg_personnel') }}
)

select
    -- 主键
    tr.training_id,

    -- 人员信息
    tr.personnel_id,
    p.personnel_code,
    p.personnel_name,
    p.department,
    p.job_position,

    -- 课程信息
    tr.course_code,
    tr.course_name,
    tr.course_type,

    -- 培训信息
    tr.training_date,
    tr.training_duration,
    tr.trainer,

    -- 考核信息
    tr.assessment_score,
    tr.assessment_result,
    case
        when tr.assessment_result = '通过' then true
        when tr.assessment_result = '未通过' then false
        else null
    end as is_passed,

    -- 证书信息
    tr.certificate_no,
    tr.valid_from,
    tr.valid_to,

    -- 有效性计算
    case
        when tr.valid_to is not null and tr.valid_to >= current_date then true
        when tr.valid_to is null then null
        else false
    end as is_certificate_valid,
    case
        when tr.valid_to is not null
        then tr.valid_to - current_date
        else null
    end as days_until_expiry,

    -- 状态
    tr.training_status,

    -- 审计字段
    tr.create_date

from training_record tr
left join personnel p on tr.personnel_id = p.personnel_id
