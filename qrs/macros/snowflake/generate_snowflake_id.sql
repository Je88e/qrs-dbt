{% macro generate_snowflake_id() %}
    {% if target.type == 'postgres' %}
        generate_snowflake_id({{ var('snowflake_machine_id', 1) }})
    {% else %}
        (((extract(epoch from now())::bigint * 1000 - 1704067200000) << 22)
         | (({{ var('snowflake_machine_id', 1) }} & 1023) << 12)
         | (floor(random() * 4096)::int))::bigint
    {% endif %}
{% endmacro %}
