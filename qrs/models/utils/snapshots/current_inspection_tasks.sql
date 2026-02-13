{{ config(materialized='view') }}

/*
    当前状态视图: current_inspection_tasks
    描述: 获取检验任务的最新状态（排除已删除记录）

    使用场景:
    - 下游模型需要获取检验任务当前状态时使用此视图
    - 任务执行进度追踪
*/

select
    *
from {{ ref('snap_inspection_tasks') }}
where dbt_valid_to = '9999-12-31'::date
  and dbt_is_deleted = 'False'
