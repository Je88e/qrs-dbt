/*
    审计模型: audit_change_controls_rows
    描述: 变更控制数据行级对比审计
    
    审计范围: 所有变更控制数据
    目标匹配率: >= 99.5%
    
    使用方法:
    1. 编译: dbt compile --select audit_change_controls_rows
    2. 查看结果: 在 target/compiled 目录查看生成的 SQL
    3. 执行: 复制 SQL 到查询工具执行
*/

{# 定义源表查询（Staging 层）#}
{% set source_query %}
select
    change_id,
    change_code,
    change_title,
    change_type,
    change_category,
    initiator,
    {{ standardize_for_audit('initiate_date', 'date') }} as initiate_date,
    priority,
    change_status
from {{ ref('stg_change_control') }}
{% endset %}

{# 定义目标表查询（Business 层）#}
{% set target_query %}
select
    change_id,
    change_code,
    change_title,
    change_type,
    change_category,
    initiator,
    {{ standardize_for_audit('initiate_date', 'date') }} as initiate_date,
    priority,
    change_status
from {{ ref('fct_change_controls') }}
{% endset %}

{# 执行行级对比 #}
{{ audit_helper.compare_queries(
    a_query=source_query,
    b_query=target_query,
    primary_key="change_id",
    summarize=true
) }}

