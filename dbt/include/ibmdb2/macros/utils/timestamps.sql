{% macro ibmdb2__current_timestamp() %}
CURRENT TIMESTAMP
{% endmacro %}

{% macro ibmdb2__snapshot_string_as_time(timestamp) -%}
    {%- set result = "timestamp('" ~ timestamp ~ "')" -%}
    {{ return(result) }}
{%- endmacro %}

{% macro ibmdb2__current_timestamp_backcompat() %}
    CURRENT TIMESTAMP
{% endmacro %}

{% macro ibmdb2__current_timestamp_in_utc_backcompat() %}
CURRENT TIMESTAMP - CURRENT TIMEZONE
{% endmacro %}
