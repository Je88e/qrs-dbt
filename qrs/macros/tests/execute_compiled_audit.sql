{% macro execute_compiled_audit(audit_file_name) %}

{#
    宏: execute_compiled_audit
    描述: 执行已编译的审计 SQL 文件
    
    参数:
    - audit_file_name: 审计文件名（不含路径和扩展名）
    
    使用方法:
    dbt run-operation execute_compiled_audit --args '{"audit_file_name": "audit_purchase_orders_rows"}'
#}

{{ log("=" * 80, info=True) }}
{{ log("🔍 执行审计分析: " ~ audit_file_name, info=True) }}
{{ log("=" * 80, info=True) }}

{% if 'rows' in audit_file_name %}
    {% set audit_type = '行级审计' %}
{% elif 'columns' in audit_file_name %}
    {% set audit_type = '列级审计' %}
{% else %}
    {% set audit_type = '未知类型' %}
{% endif %}

{{ log("审计类型: " ~ audit_type, info=True) }}
{{ log("", info=True) }}

{# 根据审计类型构建查询 #}
{% if 'purchase_orders_rows' in audit_file_name or 'inspection_requests_rows' in audit_file_name or 'change_controls_rows' in audit_file_name %}

{% set audit_query %}
with a as (
    select
        purchase_order_number,
        supplier_id,
        order_type,
        order_status,
        order_date::date as order_date,
        round(coalesce(total_amount::numeric, 0), 2) as total_amount,
        trim(lower(coalesce(currency::text, ''))) as currency,
        buyer
    from {{ ref('stg_purchase_order') }}
),
b as (
    select
        purchase_order_number,
        supplier_id,
        order_type,
        order_status,
        order_date::date as order_date,
        round(coalesce(total_amount::numeric, 0), 2) as total_amount,
        trim(lower(coalesce(currency::text, ''))) as currency,
        buyer
    from {{ ref('fct_purchase_orders') }}
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
        {{ log("| 在源表(stg) | 在目标表(fct) | 记录数 | 占比(%) |", info=True) }}
        {{ log("|-------------|---------------|--------|---------|", info=True) }}
        
        {% for row in results %}
            {% set in_a = '✅ 是' if row[0] else '❌ 否' %}
            {% set in_b = '✅ 是' if row[1] else '❌ 否' %}
            {{ log("| " ~ in_a ~ " | " ~ in_b ~ " | " ~ row[2] ~ " | " ~ row[3] ~ "% |", info=True) }}
        {% endfor %}
        
        {{ log("-" * 80, info=True) }}
        {{ log("", info=True) }}
        
        {# 分析结果 #}
        {% set total_match = namespace(value=0) %}
        {% set only_in_source = namespace(value=0) %}
        {% set only_in_target = namespace(value=0) %}

        {% for row in results %}
            {% if row[0] and row[1] %}
                {% set total_match.value = row[3] %}
            {% elif row[0] and not row[1] %}
                {% set only_in_source.value = row[3] %}
            {% elif not row[0] and row[1] %}
                {% set only_in_target.value = row[3] %}
            {% endif %}
        {% endfor %}
        
        {{ log("📈 审计分析:", info=True) }}
        {{ log("  ✅ 完全匹配: " ~ total_match.value ~ "%", info=True) }}

        {% if only_in_source.value > 0 %}
            {{ log("  ⚠️  仅在源表(stg_purchase_order)存在: " ~ only_in_source.value ~ "%", info=True) }}
        {% endif %}

        {% if only_in_target.value > 0 %}
            {{ log("  ⚠️  仅在目标表(fct_purchase_orders)存在: " ~ only_in_target.value ~ "%", info=True) }}
        {% endif %}

        {{ log("", info=True) }}

        {% if total_match.value >= 99.5 %}
            {{ log("✅ 审计通过！数据一致性优秀 (>= 99.5%)", info=True) }}
        {% elif total_match.value >= 95.0 %}
            {{ log("⚠️  审计警告！数据一致性可接受 (>= 95.0%)", info=True) }}
        {% else %}
            {{ log("❌ 审计失败！数据一致性较差 (< 95.0%)", info=True) }}
        {% endif %}
    {% endif %}
{% endif %}

{% elif 'purchase_orders_columns' in audit_file_name %}

{# 列级审计 - 审计 total_amount 列 #}
{% set audit_query %}
with a_query as (
    select
        purchase_order_number,
        round(coalesce(total_amount::numeric, 0), 2) as total_amount
    from {{ ref('stg_purchase_order') }}
),
b_query as (
    select
        purchase_order_number,
        round(coalesce(total_amount::numeric, 0), 2) as total_amount
    from {{ ref('fct_purchase_orders') }}
),
joined as (
    select
        coalesce(a_query.purchase_order_number, b_query.purchase_order_number) as purchase_order_number,
        a_query.total_amount as a_query_value,
        b_query.total_amount as b_query_value,
        case
            when a_query.total_amount = b_query.total_amount then '✅: perfect match'
            when a_query.total_amount is null and b_query.total_amount is null then '✅: both are null'
            when a_query.purchase_order_number is null then '🤷: missing from a'
            when b_query.purchase_order_number is null then '🤷: missing from b'
            when a_query.total_amount is null then '🤷: value is null in a only'
            when b_query.total_amount is null then '🤷: value is null in b only'
            when a_query.total_amount != b_query.total_amount then '❌: values do not match'
            else 'unknown'
        end as match_status,
        case
            when a_query.total_amount = b_query.total_amount then 0
            when a_query.total_amount is null and b_query.total_amount is null then 1
            when a_query.purchase_order_number is null then 2
            when b_query.purchase_order_number is null then 3
            when a_query.total_amount is null then 4
            when b_query.total_amount is null then 5
            when a_query.total_amount != b_query.total_amount then 6
            else 7
        end as match_order
    from a_query
    full outer join b_query on a_query.purchase_order_number = b_query.purchase_order_number
),
aggregated as (
    select
        'total_amount' as column_name,
        match_status,
        match_order,
        count(*) as count_records
    from joined
    group by column_name, match_status, match_order
)
select
    column_name,
    match_status,
    count_records,
    round(100.0 * count_records / sum(count_records) over (), 2) as percent_of_total
from aggregated
order by match_order
{% endset %}

{% if execute %}
    {{ log("正在执行列级审计查询 (total_amount)...", info=True) }}
    {% set results = run_query(audit_query) %}

    {% if results %}
        {{ log("", info=True) }}
        {{ log("📊 列级审计结果 - total_amount:", info=True) }}
        {{ log("-" * 80, info=True) }}
        {{ log("| 匹配状态 | 记录数 | 占比(%) |", info=True) }}
        {{ log("|----------|--------|---------|", info=True) }}

        {% for row in results %}
            {{ log("| " ~ row[1] ~ " | " ~ row[2] ~ " | " ~ row[3] ~ "% |", info=True) }}
        {% endfor %}

        {{ log("-" * 80, info=True) }}
        {{ log("", info=True) }}

        {# 分析结果 #}
        {% set perfect_match = namespace(value=0) %}
        {% set mismatch = namespace(value=0) %}

        {% for row in results %}
            {% if 'perfect match' in row[1] %}
                {% set perfect_match.value = row[3] %}
            {% elif 'do not match' in row[1] %}
                {% set mismatch.value = row[3] %}
            {% endif %}
        {% endfor %}

        {{ log("📈 审计分析:", info=True) }}
        {{ log("  ✅ 完全匹配: " ~ perfect_match.value ~ "%", info=True) }}

        {% if mismatch.value > 0 %}
            {{ log("  ❌ 值不匹配: " ~ mismatch.value ~ "%", info=True) }}
        {% endif %}

        {{ log("", info=True) }}

        {% if perfect_match.value >= 99.0 %}
            {{ log("✅ 列级审计通过！数据一致性优秀 (>= 99.0%)", info=True) }}
        {% elif perfect_match.value >= 95.0 %}
            {{ log("⚠️  列级审计警告！数据一致性可接受 (>= 95.0%)", info=True) }}
        {% else %}
            {{ log("❌ 列级审计失败！数据一致性较差 (< 95.0%)", info=True) }}
        {% endif %}
    {% endif %}
{% endif %}

{% endif %}

{{ log("=" * 80, info=True) }}

{% endmacro %}

