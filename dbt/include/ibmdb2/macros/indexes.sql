{% macro ibmdb2__get_create_index_sql(relation, index_dict) -%}
  {{ log('index dict from macro:') }}
  {{ log(index_dict) }}
  {%- set index_config = adapter.parse_index(index_dict) -%}
  {%- set comma_separated_columns = ", ".join(index_config.columns) -%}
  {%- set index_name = index_config.render(relation) -%}

  create {% if index_config.unique -%}
    unique
  {%- endif %} index
  "{{ index_name }}"
  on {{ relation }} {% if index_config.type -%}
    {{ log('IBMDB2 Adapter note: index_config.type is not supported') }} 
  {%- endif %}
  ({{ comma_separated_columns }});
{% endmacro %}