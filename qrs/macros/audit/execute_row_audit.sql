{% macro execute_row_audit(source_ref, target_ref, primary_key) %}

{#
    宏: execute_row_audit
    描述: 执行行级审计并返回结果
    
    参数:
    - source_ref: 源表引用（如 'stg_purchase_order'）
    - target_ref: 目标表引用（如 'fct_purchase_orders'）
    - primary_key: 主键字段
    
    使用方法:
    dbt run-operation execute_row_audit --args '{"source_ref": "stg_purchase_order", "target_ref": "fct_purchase_orders", "primary_key": "purchase_order_number"}'
#}

{{ log("=" * 80, info=True) }}
{{ log("🔍 开始执行行级审计分析", info=True) }}
{{ log("=" * 80, info=True) }}
{{ log("源表: " ~ source_ref, info=True) }}
{{ log("目标表: " ~ target_ref, info=True) }}
{{ log("主键: " ~ primary_key, info=True) }}
{{ log("", info=True) }}

{% set audit_query %}
with a as (
    select * from {{ ref(source_ref) }}
),
b as (
    select * from {{ ref(target_ref) }}
),
a_intersect_b as (
    select * from a
    intersect
    select * from b
),
a_except_b as (
    select * from a
    except
    select * from b
),
b_except_a as (
    select * from b
    except
    select * from a
),
all_records as (
    select *, true as in_a, true as in_b from a_intersect_b
    union all
    select *, true as in_a, false as in_b from a_except_b
    union all
    select *, false as in_a, true as in_b from b_except_a
),
summary_stats as (
    select
        in_a,
        in_b,
        count(*) as count
    from all_records
    group by 1, 2
),
final as (
    select
        *,
        round(100.0 * count / sum(count) over (), 2) as percent_of_total
    from summary_stats
    order by in_a desc, in_b desc
)
select * from final
{% endset %}

{% if execute %}
    {{ log("正在执行审计查询...", info=True) }}
    {% set results = run_query(audit_query) %}
    
    {% if results %}
        {{ log("", info=True) }}
        {{ log("📊 审计结果:", info=True) }}
        {{ log("-" * 80, info=True) }}
        {{ log("| 在源表 | 在目标表 | 记录数 | 占比(%) |", info=True) }}
        {{ log("|--------|----------|--------|---------|", info=True) }}
        
        {% for row in results %}
            {{ log("| " ~ row[0] ~ " | " ~ row[1] ~ " | " ~ row[2] ~ " | " ~ row[3] ~ " |", info=True) }}
        {% endfor %}
        
        {{ log("-" * 80, info=True) }}
        {{ log("", info=True) }}
        
        {# 分析结果 #}
        {% set total_match = 0 %}
        {% set only_in_source = 0 %}
        {% set only_in_target = 0 %}
        
        {% for row in results %}
            {% if row[0] and row[1] %}
                {% set total_match = row[3] %}
            {% elif row[0] and not row[1] %}
                {% set only_in_source = row[3] %}
            {% elif not row[0] and row[1] %}
                {% set only_in_target = row[3] %}
            {% endif %}
        {% endfor %}
        
        {{ log("📈 审计分析:", info=True) }}
        {{ log("  ✅ 完全匹配: " ~ total_match ~ "%", info=True) }}
        
        {% if only_in_source > 0 %}
            {{ log("  ⚠️  仅在源表存在: " ~ only_in_source ~ "%", info=True) }}
        {% endif %}
        
        {% if only_in_target > 0 %}
            {{ log("  ⚠️  仅在目标表存在: " ~ only_in_target ~ "%", info=True) }}
        {% endif %}
        
        {{ log("", info=True) }}
        
        {% if total_match >= 99.5 %}
            {{ log("✅ 审计通过！数据一致性良好 (>= 99.5%)", info=True) }}
        {% elif total_match >= 95.0 %}
            {{ log("⚠️  审计警告！数据一致性可接受 (>= 95.0%)", info=True) }}
        {% else %}
            {{ log("❌ 审计失败！数据一致性较差 (< 95.0%)", info=True) }}
        {% endif %}
    {% endif %}
{% endif %}

{{ log("=" * 80, info=True) }}

{% endmacro %}

