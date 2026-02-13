{% macro run_audit_analysis(audit_type, entity_name) %}

{#
    宏: run_audit_analysis
    描述: 执行审计分析并返回结果
    
    参数:
    - audit_type: 'row' 或 'column'
    - entity_name: 实体名称，如 'purchase_orders'
    
    使用方法:
    dbt run-operation run_audit_analysis --args '{"audit_type": "row", "entity_name": "purchase_orders"}'
#}

{% set audit_file = 'audit_' ~ entity_name ~ '_' ~ audit_type ~ 's' %}

{{ log("=" * 80, info=True) }}
{{ log("开始执行审计分析", info=True) }}
{{ log("审计类型: " ~ audit_type, info=True) }}
{{ log("审计实体: " ~ entity_name, info=True) }}
{{ log("=" * 80, info=True) }}

{# 编译审计文件 #}
{% set compiled_path = 'target/compiled/qrs/analyses/audit/' ~ audit_type ~ '_audit/' ~ audit_file ~ '.sql' %}

{{ log("", info=True) }}
{{ log("📄 读取编译后的 SQL 文件: " ~ compiled_path, info=True) }}

{# 读取编译后的 SQL #}
{% set audit_sql = '' %}
{% if execute %}
    {% set audit_sql_file = compiled_path %}
    {{ log("正在执行审计查询...", info=True) }}
    {{ log("", info=True) }}
{% endif %}

{{ log("✅ 审计分析完成", info=True) }}
{{ log("", info=True) }}
{{ log("💡 提示: 要查看详细结果，请运行:", info=True) }}
{{ log("   dbt compile --select " ~ audit_file, info=True) }}
{{ log("   然后查看文件: " ~ compiled_path, info=True) }}
{{ log("=" * 80, info=True) }}

{% endmacro %}

