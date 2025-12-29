/*
    审计模型: audit_purchase_orders_columns
    描述: 采购订单数据列级对比审计
    
    审计策略: 增量审计
    - 第一轮: 核心业务列（total_amount, order_status）
    - 第二轮: 扩展到关联列（supplier_id, order_date）
    - 第三轮: 全部列
    
    输出指标:
    - perfect_match: 完全匹配的记录数
    - both_are_null: 两边都为 NULL 的记录数
    - values_do_not_match: 值不匹配的记录数
    - missing_from_a: 在源表中缺失
    - missing_from_b: 在目标表中缺失
    
    使用方法:
    1. 编译: dbt compile --select audit_purchase_orders_columns
    2. 执行: 复制 SQL 到查询工具执行
*/

{# 定义源表查询 #}
{% set source_query %}
select
    purchase_order_number,
    {{ standardize_for_audit('total_amount', 'numeric') }} as total_amount,
    {{ standardize_for_audit('order_status', 'string') }} as order_status,
    supplier_id,
    {{ standardize_for_audit('order_date', 'date') }} as order_date
from {{ ref('stg_purchase_order') }}
{% endset %}

{# 定义目标表查询 #}
{% set target_query %}
select
    purchase_order_number,
    {{ standardize_for_audit('total_amount', 'numeric') }} as total_amount,
    {{ standardize_for_audit('order_status', 'string') }} as order_status,
    supplier_id,
    {{ standardize_for_audit('order_date', 'date') }} as order_date
from {{ ref('fct_purchase_orders') }}
{% endset %}

{# 定义要审计的列（按优先级排序）#}
{% set columns_to_audit = [
    'total_amount',
    'order_status',
    'supplier_id',
    'order_date'
] %}

{# 循环审计每一列 #}
{% for column in columns_to_audit %}

-- ============================================
-- 审计列: {{ column }}
-- ============================================

{{ audit_helper.compare_column_values(
    a_query=source_query,
    b_query=target_query,
    primary_key="purchase_order_number",
    column_to_compare=column
) }}

{% if not loop.last %}
-- 分隔线
{% endif %}

{% endfor %}

