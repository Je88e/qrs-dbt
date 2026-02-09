{{
    config(
        materialized='view',
        tags=['qms', 'quality', 'deviation', 'pqr']
    )
}}

/*
    Model: fct_deviations
    Description: 提供偏差记录的完整信息
    Enhancement: 添加受影响领域计算字段
*/

with deviation as (
    select * from {{ ref('stg_deviation') }}
)

select
    -- 偏差主键
    deviation_id,

    -- 偏差信息
    deviation_code,
    deviation_title,
    deviation_type,
    deviation_category,

    -- 受影响领域 (新增计算字段)
    case
        when deviation_type = '工艺偏差' then '生产工序'
        when deviation_type = '物料偏差' then '物料管理'
        when deviation_type = '环境偏差' then '环境控制'
        when deviation_type = '设备偏差' then '设备运行'
        else '其他'
    end as affected_area,

    -- 关联产品批次
    product_id,
    batch_number,

    -- 发生和发现时间
    occurrence_date,
    discovery_date,

    -- 偏差描述
    deviation_description,

    -- 处理措施
    immediate_action,
    root_cause,
    corrective_action,
    preventive_action,

    -- 偏差状态
    deviation_status,

    -- 调查和审批
    investigator,
    reviewer,
    approver,
    close_date,

    -- 关闭周期（天）
    case
        when close_date is not null and discovery_date is not null
        then {{ date_diff_days('close_date', 'discovery_date') }}
        else null
    end as closure_days,

    -- 审计字段
    create_date

from deviation
