{% macro parse_numeric(value_expr) %}
case
    when {{ value_expr }} is null then null
    when nullif(trim({{ value_expr }}::text), '') is null then null
    when replace(trim({{ value_expr }}::text), ',', '') ~ '^[+-]?([0-9]+([.][0-9]+)?|[.][0-9]+)$'
        then replace(trim({{ value_expr }}::text), ',', '')::numeric
    else null
end
{% endmacro %}

