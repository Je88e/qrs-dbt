{% macro timestamp_diff_minutes(end_timestamp, start_timestamp) %}
    {{ adapter.dispatch('timestamp_diff_minutes', 'qrs')(end_timestamp, start_timestamp) }}
{% endmacro %}

{% macro default__timestamp_diff_minutes(end_timestamp, start_timestamp) %}
    round(extract(epoch from ({{ end_timestamp }} - {{ start_timestamp }})) / 60, 1)
{% endmacro %}

{% macro postgres__timestamp_diff_minutes(end_timestamp, start_timestamp) %}
    round(extract(epoch from ({{ end_timestamp }} - {{ start_timestamp }})) / 60, 1)
{% endmacro %}

{% macro snowflake__timestamp_diff_minutes(end_timestamp, start_timestamp) %}
    datediff('minute', {{ start_timestamp }}, {{ end_timestamp }})
{% endmacro %}

{% macro bigquery__timestamp_diff_minutes(end_timestamp, start_timestamp) %}
    timestamp_diff({{ end_timestamp }}, {{ start_timestamp }}, minute)
{% endmacro %}

