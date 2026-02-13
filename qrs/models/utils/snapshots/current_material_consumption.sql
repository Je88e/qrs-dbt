{{ config(materialized='view') }}

/*
    当前状态视图: current_material_consumption
    描述: 获取物料消耗记录的最新状态（排除已删除记录）

    使用场景:
    - PQR 批次物料投料谱系分析（按工单/批次追溯）
*/

select
    *
from {{ ref('snap_material_consumption') }}
where dbt_valid_to = '9999-12-31'::date
  and dbt_is_deleted = 'False'
