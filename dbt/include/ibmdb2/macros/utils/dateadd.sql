{% macro ibmdb2__dateadd(datepart, interval, from_date_or_timestamp) %}

    cast('{{ from_date_or_timestamp }}' as datetime) + {{ interval }} {{ datepart }}

{% endmacro %}