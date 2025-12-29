/*
    审计模型: audit_inspection_requests_columns
    描述: 检验申请数据列级对比审计
    
    审计策略: 增量审计
    - 核心列: request_status, priority
    - 扩展列: material_id, sample_type
    
    使用方法:
    1. 编译: dbt compile --select audit_inspection_requests_columns
    2. 执行: 复制 SQL 到查询工具执行
*/

{# 定义源表查询 #}
{% set source_query %}
select
    request_id,
    {{ standardize_for_audit('request_status', 'string') }} as request_status,
    {{ standardize_for_audit('priority', 'string') }} as priority,
    material_id,
    {{ standardize_for_audit('sample_type', 'string') }} as sample_type
from {{ ref('stg_inspection_request') }}
{% endset %}

{# 定义目标表查询 #}
{% set target_query %}
select
    request_id,
    {{ standardize_for_audit('request_status', 'string') }} as request_status,
    {{ standardize_for_audit('priority', 'string') }} as priority,
    material_id,
    {{ standardize_for_audit('sample_type', 'string') }} as sample_type
from {{ ref('fct_inspection_requests') }}
{% endset %}

{# 定义要审计的列 #}
{% set columns_to_audit = [
    'request_status',
    'priority',
    'material_id',
    'sample_type'
] %}

{# 循环审计每一列 #}
{% for column in columns_to_audit %}

-- ============================================
-- 审计列: {{ column }}
-- ============================================

{{ audit_helper.compare_column_values(
    a_query=source_query,
    b_query=target_query,
    primary_key="request_id",
    column_to_compare=column
) }}

{% if not loop.last %}
-- 分隔线
{% endif %}

{% endfor %}

