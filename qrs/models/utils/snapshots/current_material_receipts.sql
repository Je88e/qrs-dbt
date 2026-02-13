{{ config(materialized='view') }}

/*
    当前状态视图: current_material_receipts
    描述: 获取物料接收的最新状态（排除已删除记录）

    使用场景:
    - 下游模型需要获取物料接收当前状态时使用此视图
    - 来料检验状态追踪
*/

select
    *
from {{ ref('snap_material_receipts') }}
where dbt_valid_to = '9999-12-31'::date
  and dbt_is_deleted = 'False'
