{{ config(materialized='view') }}

/*
    当前状态视图: current_deviations
    描述: 获取偏差的最新状态（排除已删除记录）

    使用场景:
    - 下游模型需要获取偏差当前状态时使用此视图
    - 质量事件追踪和调查进度监控
*/

select
    *
from {{ ref('snap_deviations') }}
where dbt_valid_to = '9999-12-31'::date
  and dbt_is_deleted = 'False'
