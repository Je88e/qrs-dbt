{{ config(materialized='view') }}

/*
    当前状态视图: current_change_controls
    描述: 获取变更控制的最新状态（排除已删除记录）

    使用场景:
    - 下游模型需要获取变更控制当前状态时使用此视图
    - GMP 合规审计追踪
*/

select
    *
from {{ ref('snap_change_controls') }}
where dbt_valid_to = '9999-12-31'::date
  and dbt_is_deleted = 'False'
