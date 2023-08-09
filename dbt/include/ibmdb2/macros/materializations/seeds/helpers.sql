{% macro ibmdb2__get_batch_size() %}
  {{ return(var('ibmdb2_batch_size', 1000)) }}
{% endmacro %}