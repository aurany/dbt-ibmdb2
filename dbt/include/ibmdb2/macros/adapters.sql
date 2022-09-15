
{% macro ibmdb2__check_schema_exists(information_schema, schema) -%}
  {% set sql -%}
        SELECT COUNT(*)
        FROM SYSCAT.SCHEMATA
        WHERE UPPER(SCHEMANAME) = UPPER('{{ schema }}')
  {%- endset %}
  {{ return(run_query(sql)) }}
{% endmacro %}


{% macro ibmdb2__create_schema(relation) -%}
  {%- call statement('create_schema') -%}

  BEGIN
     IF NOT EXISTS (
       SELECT SCHEMANAME
       FROM SYSCAT.SCHEMATA
       WHERE SCHEMANAME = UPPER('{{ relation.schema }}')
     ) THEN
        PREPARE stmt FROM 'CREATE SCHEMA {{ relation.quote(schema=False).schema }}';
        EXECUTE stmt;
     END IF;
  END

  {%- endcall -%}
{% endmacro %}


{% macro ibmdb2__drop_schema(relation) -%}
  {%- call statement('drop_schema') -%}

  BEGIN
  	FOR t AS
      SELECT
        TABNAME,
        TABSCHEMA,
        (CASE WHEN TYPE='T' THEN 'TABLE' ELSE 'VIEW' END) AS TYPE
      FROM SYSCAT.TABLES t
      WHERE TABSCHEMA = UPPER('{{ relation.schema }}')
  		DO
  			PREPARE stmt FROM 'DROP '||t.TYPE||' '||t.TABSCHEMA||'.'||t.TABNAME;
  			EXECUTE stmt;
  	END FOR;
    IF EXISTS (
      SELECT SCHEMANAME
      FROM SYSCAT.SCHEMATA
      WHERE SCHEMANAME = UPPER('{{ relation.schema }}')
    ) THEN
      PREPARE stmt FROM 'DROP SCHEMA {{ relation.schema }} RESTRICT';
      EXECUTE stmt;
    END IF;
  END

  {% endcall %}
{% endmacro %}


{% macro ibmdb2__create_table_as(temporary, relation, sql) -%}

  {%- set sql_header = config.get('sql_header', none) -%}
  {%- set organize_by = config.get('organize_by', none) -%}
  {%- set table_space = config.get('table_space', none) -%}

  {{ sql_header if sql_header is not none }}

  {# Ignore temporary table type #}
  CREATE TABLE {{ relation.quote(schema=False, identifier=False) }}
    AS (
    {{ sql }}
  )
  WITH DATA
  {%- if organize_by is not none -%}
    {{ ' ORGANIZE BY ' ~ organize_by | upper }}
  {%- endif -%}
  {%- if table_space is not none -%}
    {{ ' IN ' ~ table_space | upper  }}
  {%- endif -%}

{%- endmacro %}


{% macro ibmdb2__create_view_as(relation, sql) -%}
  {%- set sql_header = config.get('sql_header', none) -%}

  {{ sql_header if sql_header is not none }}
  CREATE VIEW {{ relation.quote(schema=False, identifier=False) }} AS
  {{ sql }}

{% endmacro %}


{% macro ibmdb2__get_columns_in_relation(relation) -%}
  {% call statement('get_columns_in_relation', fetch_result=True) %}

      SELECT
          TRIM(COLNAME) AS "name",
          TRIM(TYPENAME) AS "type",
          LENGTH AS "character_maximum_length",
          LENGTH AS "numeric_precision",
          SCALE AS "numeric_scale"
      FROM SYSCAT.COLUMNS
      WHERE TABNAME = UPPER('{{ relation.identifier }}')
        {% if relation.schema %}
        AND TABSCHEMA = UPPER('{{ relation.schema }}')
        {% endif %}
      ORDER BY colno

  {% endcall %}
  {% set table = load_result('get_columns_in_relation').table %}
  {{ return(sql_convert_columns_in_relation(table)) }}
{% endmacro %}


{% macro ibmdb2__list_relations_without_caching(schema_relation) %}
  {% call statement('list_relations_without_caching', fetch_result=True) -%}

  SELECT
    TRIM(LOWER(CURRENT_SERVER)) AS "database",
    TRIM(LOWER(TABNAME)) as "name",
    TRIM(LOWER(TABSCHEMA)) as "schema",
    CASE
      WHEN TYPE = 'T' THEN 'table'
      WHEN TYPE = 'V' THEN 'view'
    END AS "table_type"
  FROM SYSCAT.TABLES
  WHERE
    TABSCHEMA = UPPER('{{ schema_relation.schema }}') AND
    TYPE IN('T', 'V')
  {% endcall %}
  {{ return(load_result('list_relations_without_caching').table) }}
{% endmacro %}


{% macro ibmdb2__rename_relation(from_relation, to_relation) -%}
  {% call statement('rename_relation') -%}

    {# Not possible to rename views in DB2 #}
    BEGIN
      DECLARE rename_stmt VARCHAR(1000);

      IF EXISTS (
        SELECT TABNAME
        FROM SYSCAT.TABLES
        WHERE TABNAME = UPPER('{{ from_relation.identifier }}') AND TABSCHEMA = UPPER('{{ from_relation.schema }}') AND TYPE = 'T'
      ) THEN
        SET rename_stmt = 'RENAME TABLE {{ from_relation.quote(schema=False, identifier=False) }} TO {{ to_relation.quote(identifier=False).identifier }}';
        PREPARE stmt FROM rename_stmt;
        EXECUTE stmt;
      END IF;
    END

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

    BEGIN
      IF EXISTS (
        SELECT TABNAME
        FROM SYSCAT.TABLES
        WHERE TABNAME = UPPER('{{ relation.identifier }}') AND TABSCHEMA = UPPER('{{ relation.schema }}') AND TYPE = 'T'
      ) THEN
        PREPARE stmt FROM 'DROP TABLE {{ relation.quote(schema=False, identifier=False) }}';
        EXECUTE stmt;
      ELSEIF EXISTS (
        SELECT TABNAME
        FROM SYSCAT.TABLES
        WHERE TABNAME = UPPER('{{ relation.identifier }}') AND TABSCHEMA = UPPER('{{ relation.schema }}') AND TYPE = 'V'
      ) THEN
        PREPARE stmt FROM 'DROP VIEW {{ relation.quote(schema=False, identifier=False) }}';
        EXECUTE stmt;
      END IF;
    END

    {%- endcall %}
{% endmacro %}


{% macro ibmdb2__make_temp_relation(base_relation, suffix) %}
    {% set tmp_identifier = 'DBT_TMP__' ~ base_relation.identifier %}
    {% set tmp_relation = base_relation.incorporate(path={"identifier": tmp_identifier}) -%}
    {% do return(tmp_relation) %}
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
        truncate table {{ relation.quote(schema=False, identifier=False) }}
        immediate
    {%- endcall %}
{% endmacro %}


{% macro ibmdb2__current_timestamp() %}
    current_timestamp
{% endmacro %}


{% macro ibmdb2__current_timestamp_in_utc() %}
    current timestamp - current timezone
{% endmacro %}
