
{% macro ibmdb2__check_schema_exists(information_schema, schema) -%}
  {% set sql -%}
        select count(*)
        from SYSCAT.SCHEMATA
        where schemaname='{{ schema }}'
  {%- endset %}
  {{ return(run_query(sql)) }}
{% endmacro %}


{% macro ibmdb2__create_schema(relation) -%}
  {%- call statement('create_schema') -%}

  BEGIN
     IF NOT EXISTS (
       SELECT schemaname
       FROM syscat.schemata
       WHERE schemaname = '{{ relation.without_identifier().schema }}'
     ) THEN
        PREPARE stmt FROM 'CREATE SCHEMA "{{ relation.without_identifier().schema }}"';
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
        tabname,
        tabschema,
        (CASE WHEN type='T' THEN 'TABLE' ELSE 'VIEW' END) AS type
      FROM syscat.tables t
      WHERE tabschema = '{{ relation.without_identifier().schema }}'
  		DO
  			PREPARE stmt FROM 'DROP '||t.type||' "'||t.tabschema||'"."'||t.tabname||'"';
  			EXECUTE stmt;
  	END FOR;
    IF EXISTS (
      SELECT schemaname
      FROM syscat.schemata
      WHERE schemaname = '{{ relation.without_identifier().schema }}'
    ) THEN
      PREPARE stmt FROM 'DROP SCHEMA "{{ relation.without_identifier().schema }}" RESTRICT';
      EXECUTE stmt;
    END IF;
  END

  {% endcall %}
{% endmacro %}


{% macro ibmdb2__create_table_as(temporary, relation, sql) -%}
  {%- set sql_header = config.get('sql_header', none) -%}

  {{ sql_header if sql_header is not none }}

  CREATE TABLE {{ relation.quote(schema=True, identifier=True) }}
  AS (
    {{ sql }}
  ) WITH DATA

{%- endmacro %}


{% macro ibmdb2__create_view_as(relation, sql) -%}
  {%- set sql_header = config.get('sql_header', none) -%}

  {{ sql_header if sql_header is not none }}
  CREATE VIEW {{ relation.quote(schema=True, identifier=True) }} AS
    {{ sql }}

{% endmacro %}


{% macro ibmdb2__get_columns_in_relation(relation) -%}
  {% call statement('get_columns_in_relation', fetch_result=True) %}

      SELECT
          trim(colname) AS "name",
          typename AS "type",
          length AS "character_maximum_length",
          length AS "numeric_precision",
          scale AS "numeric_scale"
      FROM syscat.columns
      WHERE tabname = '{{ relation.identifier }}'
        {% if relation.schema %}
        AND tabschema = '{{ relation.schema }}'
        {% endif %}
      ORDER BY colno

  {% endcall %}
  {% set table = load_result('get_columns_in_relation').table %}
  {{ return(sql_convert_columns_in_relation(table)) }}
{% endmacro %}


{% macro ibmdb2__list_relations_without_caching(schema_relation) %}
  {% call statement('list_relations_without_caching', fetch_result=True) -%}

  SELECT
    'testdb' as "database_name",
    TRIM(tabname) as "name",
    TRIM(tabschema) as "schema_name",
    CASE
      WHEN type = 'T' THEN 'table'
      WHEN type = 'V' THEN 'view'
    END AS "kind"
  FROM syscat.tables
  WHERE type IN('T', 'V') AND tabschema = '{{ schema_relation.schema }}'

  {% endcall %}
  {{ return(load_result('list_relations_without_caching').table) }}
{% endmacro %}


{% macro ibmdb2__rename_relation(from_relation, to_relation) -%}
  {% call statement('rename_relation') -%}

    {#
      Not possible to rename views in DB2 so we have to do some work. The DDL
      is selected from syscat.views and a new renamed view is created based on
      this DDL. Comments is removed from the DDL by using regexp but this could
      probably be done better.
    #}
    BEGIN
      DECLARE rename_stmt VARCHAR(1000);
      DECLARE create_stmt VARCHAR(10000);
      DECLARE delete_stmt VARCHAR(1000);

      IF EXISTS (
        SELECT tabname
        FROM syscat.tables
        WHERE tabname='{{ from_relation.identifier }}' AND tabschema='{{ from_relation.schema }}' AND type = 'T'
      ) THEN
        SET rename_stmt = 'RENAME TABLE "{{ from_relation.schema }}"."{{ from_relation.identifier }}" TO "{{ to_relation.identifier }}"';
        PREPARE stmt FROM rename_stmt;
        EXECUTE stmt;
      ELSEIF EXISTS (
        SELECT tabname
        FROM syscat.tables
        WHERE tabname='{{ from_relation.identifier }}' AND tabschema='{{ from_relation.schema }}' AND type = 'V'
      ) THEN
        SET create_stmt = (
          -- improve regexp here, use regexp_replace instead?
          -- ...or (much better solution if possible) rename view.
          SELECT
            CONCAT(
              'CREATE VIEW "{{ to_relation.schema }}"."{{ to_relation.identifier }}" AS ',
              -- remove 'create view as'
              REGEXP_REPLACE(
                -- remove comments here (single and multiline)
                REGEXP_REPLACE(
                  text,
                  '(/\*(.|[\r\n])*?\*/)|(--(.*|[\r\n]))','', 1, 1, 'i' -- removing comments
                ),
                '.*CREATE.+VIEW.+AS', '', 1, 1, 'i' -- removing CREATE (OR REPLACE) VIEW AS'
              )
            )
          FROM syscat.views
          WHERE viewschema = '{{ from_relation.schema }}' AND viewname = '{{ from_relation.identifier }}'
        );
        PREPARE stmt FROM create_stmt;
        EXECUTE stmt;
        PREPARE stmt FROM 'DROP VIEW "{{ from_relation.schema }}"."{{ from_relation.identifier }}"';
        EXECUTE stmt;
      END IF;
    END

  {%- endcall %}
{% endmacro %}


{% macro ibmdb2__list_schemas(database) %}
    {% call statement('list_schemas', fetch_result=True, auto_begin=False) -%}
        SELECT DISTINCT
          TRIM(schemaname) AS "name"
        FROM syscat.schemata
    {%- endcall %}

    {{ return(load_result('list_schemas').table) }}
{% endmacro %}


{% macro ibmdb2__drop_relation(relation) -%}
    {% call statement('drop_relation', auto_begin=False) -%}

    BEGIN
      IF EXISTS (
        SELECT tabname
        FROM syscat.tables
        WHERE tabname='{{ relation.identifier }}' AND tabschema='{{ relation.schema }}' AND type = 'T'
      ) THEN
        PREPARE stmt FROM 'DROP TABLE "{{ relation.schema }}"."{{ relation.identifier }}"';
        EXECUTE stmt;
      ELSEIF EXISTS (
        SELECT tabname
        FROM syscat.tables
        WHERE tabname='{{ relation.identifier }}' AND tabschema='{{ relation.schema }}' AND type = 'V'
      ) THEN
        PREPARE stmt FROM 'DROP VIEW "{{ relation.schema }}"."{{ relation.identifier }}"';
        EXECUTE stmt;
      END IF;
    END

    {%- endcall %}
{% endmacro %}


{% macro ibmdb2__current_timestamp() -%}
  CURRENT_TIMESTAMP
{%- endmacro %}


{% macro ibmdb2__make_temp_relation(base_relation, suffix) %}
    {% set tmp_identifier = 'dbt_tmp___' ~ base_relation.identifier %}
    {% set tmp_relation = base_relation.incorporate(
                                path={"identifier": tmp_identifier}) -%}

    {% do return(tmp_relation) %}
{% endmacro %}


{% macro ibmdb2__get_columns_in_query(select_sql) %}
    {% call statement('get_columns_in_query', fetch_result=True, auto_begin=False) -%}
        select * from (
            {{ select_sql }}
        ) as dbt_sbq
        where false
        limit 0
    {% endcall %}

    {{ return(load_result('get_columns_in_query').table.columns | map(attribute='name') | list) }}
{% endmacro %}
