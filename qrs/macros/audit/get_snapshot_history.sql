{% macro get_snapshot_history(snapshot_name, unique_key_column, unique_key_value) %}

{#
    宏: get_snapshot_history
    描述: 获取指定记录的完整变更历史
    
    参数:
    - snapshot_name: 快照表名称
    - unique_key_column: 主键列名
    - unique_key_value: 主键值
    
    返回: 指定记录的所有历史版本，按时间倒序排列
    
    示例:
    {{ get_snapshot_history('snap_purchase_orders', 'purchase_order_number', 'PO-2024-001') }}
#}

select
    *,
    -- 计算本版本持续天数
    case 
        when valid_to = '9999-12-31' then current_date - valid_from::date
        else valid_to::date - valid_from::date
    end as duration_days,
    -- 获取下一次变更时间
    lead(valid_from) over (
        partition by {{ unique_key_column }}
        order by valid_from
    ) as next_change_date,
    -- 版本号
    row_number() over (
        partition by {{ unique_key_column }}
        order by valid_from
    ) as version_number
from {{ ref(snapshot_name) }}
where {{ unique_key_column }} = '{{ unique_key_value }}'
order by valid_from desc

{% endmacro %}

