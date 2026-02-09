{{
    config(
        materialized='view',
        tags=['mes', 'personnel', 'qualification', 'pqr']
    )
}}

/*
    Model: dim_personnel_qualifications
    Description: 人员资质维度 - 增强人员维度，关注资质和培训状态
*/

with personnel as (
    select * from {{ ref('stg_personnel') }}
),

analyst as (
    select * from {{ ref('stg_analyst') }}
),

workshop as (
    select * from {{ ref('stg_workshop') }}
),

production_line as (
    select * from {{ ref('stg_production_line') }}
),

-- 获取每个人员的最新培训记录
training_record as (
    select * from {{ ref('stg_training_record') }}
),

latest_gmp_training as (
    select
        personnel_id,
        training_date as latest_gmp_training_date,
        valid_to as gmp_cert_expiry,
        assessment_result,
        row_number() over (partition by personnel_id order by training_date desc) as rn
    from training_record
    where course_type = 'GMP基础'
),

latest_gmp_filtered as (
    select * from latest_gmp_training where rn = 1
),

-- 统计每个人员的培训完成数
training_stats as (
    select
        personnel_id,
        count(*) as total_trainings,
        count(*) filter (where assessment_result = '通过') as passed_trainings
    from training_record
    where training_status = '已完成'
    group by personnel_id
)

select
    -- 人员主键
    p.personnel_id,
    p.personnel_code,
    p.personnel_name,

    -- 部门和岗位
    p.department,
    p.job_position,
    p.skill_level,

    -- 车间和产线
    p.workshop_id,
    w.workshop_name,
    p.line_id,
    pl.line_name,

    -- 人员认证信息 (来自personnel)
    p.certification,

    -- 分析员认证信息 (如果也是分析员)
    a.analyst_id,
    a.qualification as analyst_qualification,
    a.certification_date,
    a.certification_expiry,

    -- 认证有效性
    case
        when a.certification_expiry is not null and a.certification_expiry >= current_date then true
        when a.certification_expiry is null then null
        else false
    end as is_analyst_cert_valid,
    case
        when a.certification_expiry is not null
        then a.certification_expiry - current_date
        else null
    end as days_until_analyst_cert_expiry,

    -- GMP培训状态
    lgt.latest_gmp_training_date,
    lgt.gmp_cert_expiry,
    case
        when lgt.gmp_cert_expiry is not null and lgt.gmp_cert_expiry >= current_date then true
        when lgt.gmp_cert_expiry is null then null
        else false
    end as is_gmp_cert_valid,
    case
        when lgt.gmp_cert_expiry is not null
        then lgt.gmp_cert_expiry - current_date
        else null
    end as days_until_gmp_expiry,

    -- 培训统计
    coalesce(ts.total_trainings, 0) as total_trainings,
    coalesce(ts.passed_trainings, 0) as passed_trainings,
    case
        when coalesce(ts.total_trainings, 0) > 0
        then round(coalesce(ts.passed_trainings, 0)::numeric / ts.total_trainings * 100, 2)
        else 0
    end as training_pass_rate,

    -- 综合资质状态
    case
        when (a.certification_expiry is null or a.certification_expiry >= current_date)
             and (lgt.gmp_cert_expiry is null or lgt.gmp_cert_expiry >= current_date)
        then '合格'
        when a.certification_expiry < current_date or lgt.gmp_cert_expiry < current_date
        then '待更新'
        else '待评估'
    end as qualification_status,

    -- 人员状态
    p.personnel_status,
    p.entry_date,

    -- 审计字段
    p.create_date

from personnel p
left join analyst a on p.personnel_code = a.analyst_code
left join workshop w on p.workshop_id = w.workshop_id
left join production_line pl on p.line_id = pl.line_id
left join latest_gmp_filtered lgt on p.personnel_id = lgt.personnel_id
left join training_stats ts on p.personnel_id = ts.personnel_id
