{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}

    {# 如果是生产环境，且有自定义schema，则直接使用自定义schema #}
    {%- if custom_schema_name is not none and target.name == 'prod' -%}

        {{ custom_schema_name | trim }}

    {# 其他情况（开发环境），保持默认行为：拼接 schema #}
    {%- elif custom_schema_name is not none -%}

        {{ default_schema }}_{{ custom_schema_name | trim }}

    {%- else -%}

        {{ default_schema }}

    {%- endif -%}

{%- endmacro %}