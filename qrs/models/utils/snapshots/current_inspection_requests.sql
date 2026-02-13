{{ config(materialized='view') }}

/*
    当前状态视图: current_inspection_requests
    描述: 获取检验申请的最新状态（排除已删除记录）

    使用场景:
    - 下游模型需要获取检验申请当前状态时使用此视图
    - 检验流程追踪和时效分析
*/

select
    *
from {{ ref('snap_inspection_requests') }}
where dbt_valid_to = '9999-12-31'::date
  and dbt_is_deleted = 'False'
