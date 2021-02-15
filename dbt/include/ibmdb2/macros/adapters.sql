
{% macro ibmdb2__create_schema(relation) -%}
  {%- call statement('create_schema') -%}

  BEGIN
     IF NOT EXISTS (
       SELECT SCHEMANAME
       FROM SYSCAT.SCHEMATA
       WHERE SCHEMANAME = '{{ relation.without_identifier().schema }}'
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
  	FOR T AS
      SELECT
        TABNAME,
        TABSCHEMA,
        (CASE WHEN TYPE='T' THEN 'TABLE' ELSE 'VIEW' END) AS TYPE
      FROM SYSCAT.TABLES t
      WHERE TABSCHEMA = '{{ relation.without_identifier().schema }}'
  		DO
  			PREPARE stmt FROM 'DROP '||T.TYPE||' "'||T.TABSCHEMA||'"."'||T.TABNAME||'"';
  			EXECUTE stmt;
  	END FOR;
    IF EXISTS (
      SELECT SCHEMANAME
      FROM SYSCAT.SCHEMATA
      WHERE SCHEMANAME = '{{ relation.without_identifier().schema }}'
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

  create table {{ relation.quote(schema=True, identifier=True) }}
  as (
    {{ sql }}
  ) with data

{%- endmacro %}


{% macro ibmdb2__create_view_as(relation, sql) -%}
  {%- set sql_header = config.get('sql_header', none) -%}

  {{ sql_header if sql_header is not none }}
  create view {{ relation.quote(schema=True, identifier=True) }} as
    {{ sql }}

{% endmacro %}


{% macro ibmdb2__get_columns_in_relation(relation) -%}
  {% call statement('get_columns_in_relation', fetch_result=True) %}

      select
          trim(COLNAME) AS "name",
          TYPENAME AS "type",
          LENGTH as "character_maximum_length",
          LENGTH as "numeric_precision",
          SCALE as "numeric_scale"
      from syscat.columns
      where TABNAME = '{{ relation.identifier }}'
        {% if relation.schema %}
        and TABSCHEMA = '{{ relation.schema }}'
        {% endif %}
      order by COLNO

  {% endcall %}
  {% set table = load_result('get_columns_in_relation').table %}
  {{ return(sql_convert_columns_in_relation(table)) }}
{% endmacro %}


{% macro ibmdb2__list_relations_without_caching(schema_relation) %}
  {% call statement('list_relations_without_caching', fetch_result=True) -%}

  select
    'testdb' as "database_name",
    trim(TABNAME) as "name",
    trim(TABSCHEMA) as "schema_name",
    case
      when 'T' then 'table'
      when 'V' then 'view'
    end as "kind"
  from syscat.tables
  where TYPE in ('T', 'V') and TABSCHEMA = '{{ schema_relation.schema }}'

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
        SELECT TABNAME
        FROM SYSCAT.TABLES
        WHERE TABNAME='{{ from_relation.identifier }}' AND TABSCHEMA='{{ from_relation.schema }}' AND TYPE = 'T'
      ) THEN
        SET rename_stmt = 'RENAME TABLE "{{ from_relation.schema }}"."{{ from_relation.identifier }}" TO "{{ to_relation.identifier }}"';
        PREPARE stmt FROM rename_stmt;
        EXECUTE stmt;
      ELSEIF EXISTS (
        SELECT TABNAME
        FROM SYSCAT.TABLES
        WHERE TABNAME='{{ from_relation.identifier }}' AND TABSCHEMA='{{ from_relation.schema }}' AND TYPE = 'V'
      ) THEN
        SET create_stmt = (
          -- improve regexp here, use regexp_replace instead?
          -- ...or (much better solution if possible) rename view.
          SELECT
            CONCAT(
              'CREATE VIEW "{{ to_relation.schema }}"."{{ to_relation.identifier }}" AS ',
              -- remove 'create view as'
              REGEXP_SUBSTR(
                -- remove comments here (single and multiline)
                REGEXP_REPLACE(
                  TEXT,
                  '(/\*(.|[\r\n])*?\*/)|(--(.*|[\r\n]))','', 1, 1, 'i' -- removing comments
                ),
                '(?<=\sAS)(.*\n)+', 1, 1, 'i' -- removing 'create view as'
              )
            )
          FROM SYSCAT.VIEWS
          WHERE VIEWSCHEMA = '{{ from_relation.schema }}' AND VIEWNAME = '{{ from_relation.identifier }}'
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
        select distinct
          trim(SCHEMANAME) AS "name"
        from syscat.schemata
    {%- endcall %}

    {{ return(load_result('list_schemas').table) }}
{% endmacro %}


{% macro ibmdb2__drop_relation(relation) -%}
    {% call statement('drop_relation', auto_begin=False) -%}

    BEGIN
      IF EXISTS (
        SELECT TABNAME
        FROM SYSCAT.TABLES
        WHERE TABNAME='{{ relation.identifier }}' AND TABSCHEMA='{{ relation.schema }}' AND TYPE = 'T'
      ) THEN
        PREPARE stmt FROM 'DROP TABLE "{{ relation.schema }}"."{{ relation.identifier }}"';
        EXECUTE stmt;
      ELSEIF EXISTS (
        SELECT TABNAME
        FROM SYSCAT.TABLES
        WHERE TABNAME='{{ relation.identifier }}' AND TABSCHEMA='{{ relation.schema }}' AND TYPE = 'V'
      ) THEN
        PREPARE stmt FROM 'DROP VIEW "{{ relation.schema }}"."{{ relation.identifier }}"';
        EXECUTE stmt;
      END IF;
    END

    {%- endcall %}
{% endmacro %}


{% macro ibmdb2__current_timestamp() -%}
  CURRENT_DATE
{%- endmacro %}
