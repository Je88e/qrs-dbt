{{ config(materialized='view') }}

/*
    当前状态视图: current_capas
    描述: 获取 CAPA 的最新状态（排除已删除记录）

    使用场景:
    - 下游模型需要获取 CAPA 当前状态时使用此视图
    - 纠正预防措施执行进度追踪
*/

select
    *
from {{ ref('snap_capas') }}
where dbt_valid_to = '9999-12-31'::date
  and dbt_is_deleted = 'False'
