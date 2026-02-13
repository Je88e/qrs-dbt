{{ config(materialized='view') }}

/*
    当前状态视图: current_inspection_results
    描述: 获取检验结果的最新状态（排除已删除记录）

    使用场景:
    - PQR 批次合规/OOS 统计
    - 过程能力(Cpk/Ppk)计算的基础数据
*/

select
    *
from {{ ref('snap_inspection_result') }}
where dbt_valid_to = '9999-12-31'::date
  and dbt_is_deleted = 'False'
