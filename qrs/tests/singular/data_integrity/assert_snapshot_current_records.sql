/*
    测试: test_snapshot_current_records
    描述: 验证每个主键只有一条当前有效记录
    
    失败条件:
    - 同一主键存在多条当前记录（valid_to = '9999-12-31'）
    
    使用方法:
    dbt test --select test_snapshot_current_records
*/

with current_records as (
    select
        purchase_order_number as unique_key,
        count(*) as current_record_count
    from {{ ref('snap_purchase_orders') }}
    where dbt_valid_to = '9999-12-31'::date
      and dbt_is_deleted = 'False'
    group by purchase_order_number
    having count(*) > 1
)

-- 返回有多条当前记录的主键（测试期望返回 0 行）
select 
    unique_key,
    current_record_count,
    'DUPLICATE_CURRENT_RECORD' as error_type
from current_records

