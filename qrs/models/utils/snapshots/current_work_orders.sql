{{ config(materialized='view') }}

/*
    当前状态视图: current_work_orders
    描述: 获取生产工单的最新状态（排除已删除记录）

    使用场景:
    - PQR 批次谱系/年度批次汇总等下游模型按“快照当前态”取数
*/

select
    *
from {{ ref('snap_work_order') }}
where dbt_valid_to = '9999-12-31'::date
  and dbt_is_deleted = 'False'
