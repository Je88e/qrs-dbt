{% test not_null_where(model, column_name, condition) %}

select *
from {{ model }}
where ({{ condition }}) and {{ column_name }} is null

{% endtest %}
