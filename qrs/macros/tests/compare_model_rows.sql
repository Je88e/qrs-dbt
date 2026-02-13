{% macro compare_model_rows(
    old_relation,
    new_model_ref,
    primary_key,
    columns_to_compare,
    where_clause=None
) %}

{#
    宏: compare_model_rows
    描述: 通用的行级数据对比宏，用于对比旧系统表与 dbt 模型的数据一致性
    
    参数:
    - old_relation: 旧系统表的完整路径（schema.table）
    - new_model_ref: 新模型的 ref 名称
    - primary_key: 主键列名
    - columns_to_compare: 要对比的列列表
    - where_clause: 可选的过滤条件
    
    示例:
    {{ compare_model_rows(
        old_relation='legacy_schema.purchase_orders',
        new_model_ref='fct_purchase_orders',
        primary_key='purchase_order_number',
        columns_to_compare=['order_status', 'total_amount', 'supplier_id'],
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

{# 执行对比 #}
{{ audit_helper.compare_queries(
    a_query=old_query,
    b_query=new_query,
    primary_key=primary_key,
    summarize=true
) }}

{% endmacro %}

