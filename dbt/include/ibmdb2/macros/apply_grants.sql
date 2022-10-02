{% macro ibmdb2__get_show_grant_sql(relation) %}

  {%- set schema = case_relation_part(relation.quote_policy['schema'], relation.schema) -%}
  {%- set identifier = case_relation_part(relation.quote_policy['identifier'], relation.identifier) -%}

  SELECT
    AUTHID as "grantee",
    PRIVILEGE as "privilege_type"
  FROM SYSIBMADM.PRIVILEGES
  WHERE AUTHID != CURRENT USER
    AND OBJECTNAME = '{{ identifier }}'
  {% if relation.schema %}
    AND OBJECTSCHEMA = '{{ schema }}'
  {% endif %}

{% endmacro %}