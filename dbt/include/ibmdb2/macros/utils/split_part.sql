{% macro ibmdb2__split_part(string_text, delimiter_text, part_number) %}

    REGEXP_SUBSTR('{{ string_text }}', '([^{{ delimiter_text }}]*){{ delimiter_text }}?', 1, {{ part_number }}, '', 1)

{% endmacro %}
