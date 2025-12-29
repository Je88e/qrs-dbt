/*
    审计模型: audit_change_controls_columns
    描述: 变更控制数据列级对比审计
    
    审计策略: 增量审计
    - 核心列: change_status, priority
    - 扩展列: change_type, change_category
    
    使用方法:
    1. 编译: dbt compile --select audit_change_controls_columns
    2. 执行: 复制 SQL 到查询工具执行
*/

{# 定义源表查询 #}
{% set source_query %}
select
    change_id,
    {{ standardize_for_audit('change_status', 'string') }} as change_status,
    {{ standardize_for_audit('priority', 'string') }} as priority,
    {{ standardize_for_audit('change_type', 'string') }} as change_type,
    {{ standardize_for_audit('change_category', 'string') }} as change_category
from {{ ref('stg_change_control') }}
{% endset %}

{# 定义目标表查询 #}
{% set target_query %}
select
    change_id,
    {{ standardize_for_audit('change_status', 'string') }} as change_status,
    {{ standardize_for_audit('priority', 'string') }} as priority,
    {{ standardize_for_audit('change_type', 'string') }} as change_type,
    {{ standardize_for_audit('change_category', 'string') }} as change_category
from {{ ref('fct_change_controls') }}
{% endset %}

{# 定义要审计的列 #}
{% set columns_to_audit = [
    'change_status',
    'priority',
    'change_type',
    'change_category'
] %}

{# 循环审计每一列 #}
{% for column in columns_to_audit %}

-- ============================================
-- 审计列: {{ column }}
-- ============================================

{{ audit_helper.compare_column_values(
    a_query=source_query,
    b_query=target_query,
    primary_key="change_id",
    column_to_compare=column
) }}

{% if not loop.last %}
-- 分隔线
{% endif %}

{% endfor %}

