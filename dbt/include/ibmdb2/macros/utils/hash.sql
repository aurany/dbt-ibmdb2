{% macro ibmdb2__hash(field) -%}
    hex(hash({{field}}))
{%- endmacro %}
