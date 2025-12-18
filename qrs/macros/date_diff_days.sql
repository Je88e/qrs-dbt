{% macro date_diff_days(end_date, start_date) %}
    {{ adapter.dispatch('date_diff_days', 'qrs')(end_date, start_date) }}
{% endmacro %}

{% macro default__date_diff_days(end_date, start_date) %}
    cast({{ end_date }} as date) - cast({{ start_date }} as date)
{% endmacro %}

{% macro postgres__date_diff_days(end_date, start_date) %}
    cast({{ end_date }} as date) - cast({{ start_date }} as date)
{% endmacro %}

{% macro snowflake__date_diff_days(end_date, start_date) %}
    datediff('day', {{ start_date }}, {{ end_date }})
{% endmacro %}

{% macro bigquery__date_diff_days(end_date, start_date) %}
    date_diff(cast({{ end_date }} as date), cast({{ start_date }} as date), day)
{% endmacro %}

