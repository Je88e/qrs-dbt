{% macro standardize_for_audit(column_name, data_type) %}

{#
    宏: standardize_for_audit
    描述: 标准化列值以便审计对比，处理常见的数据差异问题
    
    参数:
    - column_name: 列名
    - data_type: 数据类型
      - 'timestamp': 时间戳（转 UTC）
      - 'numeric': 数值（保留 2 位小数）
      - 'string': 字符串（trim + lower）
      - 'boolean': 布尔值（标准化）
      - 'date': 日期（标准格式）
    
    示例:
    {{ standardize_for_audit('create_date', 'timestamp') }}
    {{ standardize_for_audit('total_amount', 'numeric') }}
    {{ standardize_for_audit('order_status', 'string') }}
#}

{% if data_type == 'timestamp' %}
    {{ column_name }}::timestamp at time zone 'UTC'
    
{% elif data_type == 'numeric' %}
    round(coalesce({{ column_name }}::numeric, 0), 2)
    
{% elif data_type == 'string' %}
    trim(lower(coalesce({{ column_name }}::text, '')))
    
{% elif data_type == 'boolean' %}
    case
        when {{ column_name }}::text in ('true', 't', '1', 'yes', 'y', 'True', 'TRUE') then true
        when {{ column_name }}::text in ('false', 'f', '0', 'no', 'n', 'False', 'FALSE') then false
        else null
    end
    
{% elif data_type == 'date' %}
    {{ column_name }}::date
    
{% else %}
    {{ column_name }}
    
{% endif %}

{% endmacro %}

