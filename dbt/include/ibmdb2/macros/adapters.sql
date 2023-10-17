
{% macro case_relation_part(quoting, relation_part) %}
  {% if quoting == False %}
    {%- set relation_part = relation_part|upper -%}
  {% endif %}
  {{ return(relation_part) }}
{% endmacro %}


{% macro ibmdb2__check_schema_exists(information_schema, schema) -%}

  {# This schema will ignore quoting and therefore also upper vs lowercase #}
  {%- set schema = case_relation_part(information_schema.quote_policy['schema'], schema) -%}

  {% set sql -%}

SELECT COUNT(*)
FROM SYSCAT.SCHEMATA
WHERE SCHEMANAME = '{{ schema }}'

  {%- endset %}
  {{ return(run_query(sql)) }}
{% endmacro %}


{% macro ibmdb2__create_schema(relation) -%}
  {%- call statement('create_schema') -%}

  {%- set schema = case_relation_part(relation.quote_policy['schema'], relation.without_identifier()) -%}

BEGIN
  IF NOT EXISTS (
    SELECT SCHEMANAME
    FROM SYSCAT.SCHEMATA
    WHERE SCHEMANAME = '{{ schema }}'
  ) THEN
    PREPARE stmt FROM 'CREATE SCHEMA {{ schema }}';
    EXECUTE stmt;
  END IF;
END

  {%- endcall -%}
{% endmacro %}


{% macro ibmdb2__drop_schema(relation) -%}
  {%- call statement('drop_schema') -%}

  {%- set schema = case_relation_part(relation.quote_policy['schema'], relation.schema) -%}

BEGIN
	FOR t AS
    SELECT
      TABNAME,
      TABSCHEMA,
      (CASE WHEN TYPE='T' THEN 'TABLE' ELSE 'VIEW' END) AS TYPE
    FROM SYSCAT.TABLES t
    WHERE TABSCHEMA = '{{ schema }}'
		DO
			PREPARE stmt FROM 'DROP '||t.TYPE||' '||t.TABSCHEMA||'.'||t.TABNAME;
			EXECUTE stmt;
	END FOR;
  IF EXISTS (
    SELECT SCHEMANAME
    FROM SYSCAT.SCHEMATA
    WHERE SCHEMANAME = '{{ schema }}'
  ) THEN
    PREPARE stmt FROM 'DROP SCHEMA {{ schema }} RESTRICT';
    EXECUTE stmt;
  END IF;
END

  {% endcall %}
{% endmacro %}


{% macro ibmdb2__create_table_as(temporary, relation, sql) -%}

  {%- set sql_header = config.get('sql_header', none) -%}
  {%- set table_space = config.get('table_space', none) -%}
  {%- set organize_by = config.get('organize_by', none) -%}
  {%- set distribute_by = config.get('distribute_by', none) -%}

  {{ sql_header if sql_header is not none }}

  {# Ignore temporary table type #}
CREATE TABLE {{ relation }} AS (
  {{ sql }}
)
WITH DATA

  {%- if table_space is not none -%}
    {{ ' ' }}
IN {{ table_space | upper  }}
  {%- endif -%}

  {%- if organize_by is not none -%}
    {{ ' ' }}
ORGANIZE BY {{ organize_by | upper }}
  {%- endif -%}

  {%- if distribute_by is not none -%}
    {%- set distribute_by_type = distribute_by['type'] | lower -%}
    {{ ' ' }}
DISTRIBUTE BY {{ distribute_by_type | upper }}
    {%- if distribute_by_type == 'hash' -%}
      {%- set distribute_by_columns = distribute_by['columns'] -%}
(
      {% for column in distribute_by_columns %}
{{ column }}
        {% if not loop.last %},{% endif %}
      {% endfor %}
)
    {%- endif -%}
  {%- endif -%}

{%- endmacro %}


{% macro ibmdb2__create_view_as(relation, sql) -%}

  {%- set sql_header = config.get('sql_header', none) -%}

  {{ sql_header if sql_header is not none }}
CREATE VIEW {{ relation }} AS 
  {{ sql }}

{% endmacro %}


{% macro ibmdb2__get_columns_in_relation(relation) -%}
  {% call statement('get_columns_in_relation', fetch_result=True) %}

  {%- set schema = case_relation_part(relation.quote_policy['schema'], relation.schema) -%}
  {%- set identifier = case_relation_part(relation.quote_policy['identifier'], relation.identifier) -%}

SELECT
  TRIM(COLNAME) AS "name",
  TRIM(TYPENAME) AS "type",
  LENGTH AS "character_maximum_length",
  LENGTH AS "numeric_precision",
  SCALE AS "numeric_scale"
FROM SYSCAT.COLUMNS
WHERE TABNAME = '{{ identifier }}'
  {% if relation.schema %}
  AND TABSCHEMA = '{{ schema }}'
  {% endif %}
  AND HIDDEN = ''
ORDER BY colno

  {% endcall %}
  {% set table = load_result('get_columns_in_relation').table %}
  {{ return(sql_convert_columns_in_relation(table)) }}
{% endmacro %}


{% macro ibmdb2__list_relations_without_caching(schema_relation) %}
  {% call statement('list_relations_without_caching', fetch_result=True) -%}

  {%- set schema = case_relation_part(schema_relation.quote_policy['schema'], schema_relation.schema) -%}

SELECT
  '{{ schema_relation.database }}' AS "database",
  TRIM(TABNAME) as "name",
  TRIM(TABSCHEMA) as "schema",
  CASE
    WHEN TYPE = 'T' THEN 'table'
    WHEN TYPE = 'V' THEN 'view'
  END AS "table_type"
FROM SYSCAT.TABLES
WHERE
  TABSCHEMA = '{{ schema }}' AND
  TYPE IN('T', 'V')

  {% endcall %}
  {{ return(load_result('list_relations_without_caching').table) }}
{% endmacro %}


{% macro ibmdb2__rename_relation(from_relation, to_relation) -%}
  {% call statement('rename_relation') -%}

  {% if from_relation.is_table %}
RENAME TABLE {{ from_relation }} TO {{ to_relation.replace_path(schema=None) }}
  {% endif %}

  {% if from_relation.is_view %}
    {% do exceptions.raise_compiler_error('IBMDB2 Adapter error: Renaming of views is not supported.') %}
  {% endif %}

  {%- endcall %}
{% endmacro %}


{% macro ibmdb2__list_schemas(database) %}
  {% call statement('list_schemas', fetch_result=True, auto_begin=False) -%}

SELECT DISTINCT
  TRIM(SCHEMANAME) AS "schema"
FROM SYSCAT.SCHEMATA

  {%- endcall %}
  {{ return(load_result('list_schemas').table) }}
{% endmacro %}


{% macro ibmdb2__drop_relation(relation) -%}
  {% call statement('drop_relation', auto_begin=False) -%}

  {%- set schema = case_relation_part(relation.quote_policy['schema'], relation.schema) -%}
  {%- set identifier = case_relation_part(relation.quote_policy['identifier'], relation.identifier) -%}

BEGIN
  IF EXISTS (
    SELECT TABNAME
    FROM SYSCAT.TABLES
    WHERE
      TABSCHEMA = '{{ schema }}' AND
      TABNAME = '{{ identifier }}' AND
      TYPE = (CASE
        WHEN '{{ relation.type }}' = 'view' THEN 'V' ELSE 'T'
      END)
  ) THEN
    PREPARE stmt FROM 'DROP {{ relation.type | upper }} {{ relation }}';
    EXECUTE stmt;
    COMMIT;
  END IF;
END

  {%- endcall %}
{% endmacro %}


{% macro ibmdb2__get_columns_in_query(select_sql) %}
  {% call statement('get_columns_in_query', fetch_result=True, auto_begin=False) -%}

SELECT * FROM (
    {{ select_sql }}
) AS dbt_sbq
WHERE 0=1
FETCH FIRST 0 ROWS ONLY

  {% endcall %}
  {{ return(load_result('get_columns_in_query').table.columns | map(attribute='name') | list) }}
{% endmacro %}


{% macro ibmdb2__truncate_relation(relation) %}
  {% call statement('truncate_relation') -%}
TRUNCATE TABLE {{ relation }}
IMMEDIATE
  {%- endcall %}
{% endmacro %}


{% macro ibmdb2__get_binding_char() %}
  {{ return('?') }}
{% endmacro %}


{% macro ibmdb2__snapshot_hash_arguments(args) -%}
    hash({%- for arg in args -%}
        coalesce(cast({{ arg }} as varchar ), '')
        {% if not loop.last %} || '|' || {% endif %}
    {%- endfor -%})
{%- endmacro %}


{% macro ibmdb2__post_snapshot(staging_relation) %}
    {% do adapter.truncate_relation(staging_relation) %}
    {% do adapter.drop_relation(staging_relation) %}
{% endmacro %}
