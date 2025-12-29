/*
    审计模型: audit_inspection_requests_rows
    描述: 检验申请数据行级对比审计
    
    审计范围: 所有检验申请数据
    目标匹配率: >= 99.5%
    
    使用方法:
    1. 编译: dbt compile --select audit_inspection_requests_rows
    2. 查看结果: 在 target/compiled 目录查看生成的 SQL
    3. 执行: 复制 SQL 到查询工具执行
*/

{# 定义源表查询（Staging 层）#}
{% set source_query %}
select
    request_id,
    material_id,
    batch_number,
    sample_type,
    {{ standardize_for_audit('request_date', 'date') }} as request_date,
    requester,
    inspection_type,
    priority,
    request_status
from {{ ref('stg_inspection_request') }}
{% endset %}

{# 定义目标表查询（Business 层）#}
{% set target_query %}
select
    request_id,
    material_id,
    batch_number,
    sample_type,
    {{ standardize_for_audit('request_date', 'date') }} as request_date,
    requester,
    inspection_type,
    priority,
    request_status
from {{ ref('fct_inspection_requests') }}
{% endset %}

{# 执行行级对比 #}
{{ audit_helper.compare_queries(
    a_query=source_query,
    b_query=target_query,
    primary_key="request_id",
    summarize=true
) }}

