{% macro compare_model_columns(
    old_relation,
    new_model_ref,
    primary_key,
    columns_to_compare,
    where_clause=None
) %}

{#
    宏: compare_model_columns
    描述: 逐列对比两个数据集，精确定位差异列
    
    参数:
    - old_relation: 旧系统表的完整路径（schema.table）
    - new_model_ref: 新模型的 ref 名称
    - primary_key: 主键列名
    - columns_to_compare: 要对比的列列表
    - where_clause: 可选的过滤条件
    
    输出: 每列的对比结果，包含以下状态
    - perfect_match: 完全匹配
    - both_are_null: 两边都为 NULL
    - values_do_not_match: 值不匹配
    - missing_from_a: 在旧系统中缺失
    - missing_from_b: 在新系统中缺失
    - value_is_null_in_a_only: 仅在旧系统中为 NULL
    - value_is_null_in_b_only: 仅在新系统中为 NULL
    
    示例:
    {{ compare_model_columns(
        old_relation='legacy_schema.purchase_orders',
        new_model_ref='fct_purchase_orders',
        primary_key='purchase_order_number',
        columns_to_compare=['total_amount', 'order_status'],
        where_clause="order_date >= '2024-01-01'"
    ) }}
#}

{# 构建旧系统查询 #}
{% set old_query %}
select
    {{ primary_key }},
    {% for col in columns_to_compare %}
    {{ col }}{{ "," if not loop.last else "" }}
    {% endfor %}
from {{ old_relation }}
{% if where_clause %}
where {{ where_clause }}
{% endif %}
{% endset %}

{# 构建新系统查询 #}
{% set new_query %}
select
    {{ primary_key }},
    {% for col in columns_to_compare %}
    {{ col }}{{ "," if not loop.last else "" }}
    {% endfor %}
from {{ ref(new_model_ref) }}
{% if where_clause %}
where {{ where_clause }}
{% endif %}
{% endset %}

{# 循环对比每一列 #}
{% for column in columns_to_compare %}

-- ============================================
-- 列审计: {{ column }}
-- ============================================

{{ audit_helper.compare_column_values(
    a_query=old_query,
    b_query=new_query,
    primary_key=primary_key,
    column_to_compare=column
) }}

{% if not loop.last %}
UNION ALL
{% endif %}

{% endfor %}

{% endmacro %}

