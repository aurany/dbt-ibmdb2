{% macro ibmdb2__split_part(string_text, delimiter_text, part_number) %}

  {% if part_number == 0 %}
    {{ exceptions.raise_compiler_error("Invalid argument `part_number` must not be 0.") }}
  {% elif part_number >= 1 %}
    REGEXP_SUBSTR({{ string_text }}, '([^' || REGEXP_REPLACE({{ delimiter_text }}, '([\|.^$\\+?*\[\]])', '\\$1') || ']*)' || REGEXP_REPLACE({{ delimiter_text }}, '([\|.^$\\+?*\[\]])', '\\$1') || '?', 1, {{ part_number }}, '', 1)
  {% else %}
    CASE
      WHEN REGEXP_COUNT({{ string_text }}, '([^' || REGEXP_REPLACE({{ delimiter_text }}, '([\|.^$\\+?*\[\]])', '\\$1') || ']*)' || REGEXP_REPLACE({{ delimiter_text }}, '([\|.^$\\+?*\[\]])', '\\$1') || '?') > 0 THEN REGEXP_SUBSTR({{ string_text }}, '([^' || REGEXP_REPLACE({{ delimiter_text }}, '([\|.^$\\+?*\[\]])', '\\$1') || ']*)' || REGEXP_REPLACE({{ delimiter_text }}, '([\|.^$\\+?*\[\]])', '\\$1') || '?', 1, REGEXP_COUNT({{ string_text }}, '([^' || REGEXP_REPLACE({{ delimiter_text }}, '([\|.^$\\+?*\[\]])', '\\$1') || ']*)' || REGEXP_REPLACE({{ delimiter_text }}, '([\|.^$\\+?*\[\]])', '\\$1') || '?') + {{ part_number }}, '', 1)
      ELSE NULL
    END
  {% endif %}

{% endmacro %}
