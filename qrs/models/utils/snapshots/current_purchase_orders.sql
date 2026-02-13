{{ config(materialized='view') }}

/*
    当前状态视图: current_purchase_orders
    描述: 获取采购订单的最新状态（排除已删除记录）

    使用场景:
    - 下游模型需要获取订单当前状态时使用此视图
    - 避免在每个模型中重复编写 valid_to 过滤逻辑
*/

select
    *
from {{ ref('snap_purchase_orders') }}
where dbt_valid_to = '9999-12-31'::date
  and dbt_is_deleted = 'False'
