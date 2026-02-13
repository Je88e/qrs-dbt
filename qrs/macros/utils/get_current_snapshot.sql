{% macro get_current_snapshot(snapshot_name, as_of_date=None) %}

{#
    宏: get_current_snapshot
    描述: 获取快照表的当前有效记录或指定时间点的记录
    
    参数:
    - snapshot_name: 快照表名称
    - as_of_date: 可选，指定时间点（格式: 'YYYY-MM-DD'）
    
    返回: 当前有效且未删除的记录
    
    示例:
    -- 获取当前记录
    select * from ({{ get_current_snapshot('snap_purchase_orders') }}) as current_data
    
    -- 获取 2024-01-01 时的记录
    select * from ({{ get_current_snapshot('snap_purchase_orders', '2024-01-01') }}) as historical_data
#}

(
    select *
    from {{ ref(snapshot_name) }}
    where 
        {% if as_of_date %}
        dbt_valid_from <= '{{ as_of_date }}'::date
        and (dbt_valid_to > '{{ as_of_date }}'::date or dbt_valid_to = '9999-12-31')
        {% else %}
        dbt_valid_to = '9999-12-31'
        {% endif %}
        and dbt_is_deleted = 'False'
)

{% endmacro %}

