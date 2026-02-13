/*
    测试: test_snapshot_integrity
    描述: 验证快照表的数据完整性
    
    失败条件:
    - 存在时间重叠的记录
    - 存在 valid_from > valid_to 的记录（除了当前记录）
    
    使用方法:
    dbt test --select test_snapshot_integrity
*/

with snapshot_checks as (
    select
        'snap_purchase_orders' as snapshot_name,
        purchase_order_number as unique_key,
        dbt_valid_from,
        dbt_valid_to,
        snapshot_id
    from {{ ref('snap_purchase_orders') }}
),

-- 检查时间逻辑错误：valid_from >= valid_to（当前记录除外）
time_logic_errors as (
    select
        snapshot_name,
        unique_key,
        dbt_valid_from,
        dbt_valid_to,
        'TIME_LOGIC_ERROR' as error_type,
        'dbt_valid_from >= dbt_valid_to' as error_description
    from snapshot_checks
    where
        dbt_valid_from >= dbt_valid_to
        and dbt_valid_to != '9999-12-31'::date
),

-- 检查时间重叠
time_overlaps as (
    select
        s1.snapshot_name,
        s1.unique_key,
        s1.valid_from,
        s1.dbt_valid_to,
        'TIME_OVERLAP' as error_type,
        'Records have overlapping valid periods' as error_description
    from snapshot_checks s1
    join snapshot_checks s2
        on s1.unique_key = s2.unique_key
        and s1.snapshot_id != s2.snapshot_id
    where
        s1.dbt_valid_from < s2.dbt_valid_to
        and s2.dbt_valid_from < s1.dbt_valid_to
        and s1.dbt_valid_to != '9999-12-31'::date
        and s2.dbt_valid_to != '9999-12-31'::date
),

-- 合并所有错误
all_errors as (
    select * from time_logic_errors
    union all
    select * from time_overlaps
)

-- 返回所有错误（测试期望返回 0 行）
select * from all_errors

