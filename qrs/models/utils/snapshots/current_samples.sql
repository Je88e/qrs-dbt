{{ config(materialized='view') }}

/*
    当前状态视图: current_samples
    描述: 获取 LIMS 样品的最新状态（排除已删除记录）

    使用场景:
    - 将检验结果按 sample_id 关联到 batch_number / material_id
*/

select
    *
from {{ ref('snap_sample') }}
where dbt_valid_to = '9999-12-31'::date
  and dbt_is_deleted = 'False'
