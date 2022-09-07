{% macro ibmdb2__position(substring_text, string_text) %}

    position(
        {{ substring_text }}, {{ string_text }}
    )
    
{%- endmacro -%}