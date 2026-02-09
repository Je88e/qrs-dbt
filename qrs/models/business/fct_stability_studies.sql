{{
    config(
        materialized='view',
        tags=['lims', 'stability', 'quality', 'pqr']
    )
}}

/*
    Model: fct_stability_studies
    Description: 稳定性研究 - 提供稳定性样品的检验结果和趋势分析
*/

with stability_study as (
    select * from {{ ref('stg_stability_study') }}
),

analyst as (
    select * from {{ ref('stg_analyst') }}
)

select
    -- 主键
    ss.study_id,
    ss.study_code,

    -- 产品批次
    ss.product_id,
    ss.batch_number,

    -- 研究条件
    ss.study_type,
    ss.storage_condition,
    ss.timepoint,
    ss.timepoint_months,

    -- 样品和检验
    ss.sample_id,
    ss.test_item_id,
    ss.test_item_name,

    -- 检验结果
    ss.test_value,
    ss.test_unit,
    ss.specification,
    ss.result_status,

    -- 是否符合规格
    case
        when ss.result_status = '符合' then true
        when ss.result_status = '不符合' then false
        else null
    end as is_within_spec,

    -- 是否有趋势异常
    case
        when ss.result_status = '趋势异常' then true
        else false
    end as has_trend_alert,

    -- 检测信息
    ss.test_date,
    ss.analyst_id,
    a.analyst_name,

    -- 研究状态
    ss.study_status,

    -- 审计字段
    ss.create_date

from stability_study ss
left join analyst a on ss.analyst_id = a.analyst_id
