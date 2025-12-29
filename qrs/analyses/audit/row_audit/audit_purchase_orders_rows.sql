/*
    审计模型: audit_purchase_orders_rows
    描述: 采购订单数据行级对比审计
    
    审计范围: 所有采购订单数据
    目标匹配率: >= 99.5%
    
    使用方法:
    1. 编译: dbt compile --select audit_purchase_orders_rows
    2. 查看结果: 在 target/compiled 目录查看生成的 SQL
    3. 执行: 复制 SQL 到查询工具执行
    
    结果解读:
    - IN_A=TRUE, IN_B=TRUE: 完全匹配的记录
    - IN_A=TRUE, IN_B=FALSE: 仅在源表存在（可能是 staging 层过滤）
    - IN_A=FALSE, IN_B=TRUE: 仅在目标表存在（可能是业务逻辑生成）
*/

{# 定义源表查询（Staging 层）#}
{% set source_query %}
select
    purchase_order_number,
    supplier_id,
    order_type,
    order_status,
    {{ standardize_for_audit('order_date', 'date') }} as order_date,
    {{ standardize_for_audit('total_amount', 'numeric') }} as total_amount,
    {{ standardize_for_audit('currency', 'string') }} as currency,
    buyer
from {{ ref('stg_purchase_order') }}
{% endset %}

{# 定义目标表查询（Business 层）#}
{% set target_query %}
select
    purchase_order_number,
    supplier_id,
    order_type,
    order_status,
    {{ standardize_for_audit('order_date', 'date') }} as order_date,
    {{ standardize_for_audit('total_amount', 'numeric') }} as total_amount,
    {{ standardize_for_audit('currency', 'string') }} as currency,
    buyer
from {{ ref('fct_purchase_orders') }}
{% endset %}

{# 执行行级对比 #}
{{ audit_helper.compare_queries(
    a_query=source_query,
    b_query=target_query,
    primary_key="purchase_order_number",
    summarize=true
) }}

