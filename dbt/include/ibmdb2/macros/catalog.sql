{% macro ibmdb2__get_catalog(information_schema, schemas) -%}

  {%- call statement('catalog', fetch_result=True) -%}

    WITH columns AS (
      SELECT
        COLNAME,
        TYPENAME,
        CURRENT_SERVER AS DATABASE, -- Should be replaced by DB from profile
        TABNAME,
        TABSCHEMA,
        COLNO
      FROM SYSCAT.COLUMNS
    ),
    tables AS (
      SELECT
        CURRENT_SERVER AS DATABASE, -- Should be replaced by DB  from profile
        TABSCHEMA,
        TABNAME,
        OWNER,
        CASE
          WHEN TYPE = 'T' THEN 'TABLE' -- Upcase here to work with tests
          WHEN TYPE = 'V' THEN 'VIEW'  -- Upcase here to work with tests
        END AS TYPE
      FROM SYSCAT.TABLES
      WHERE TYPE IN('T', 'V')
    )
    SELECT
      TRIM(tables.DATABASE) AS "table_database",
      TRIM(tables.TABSCHEMA) AS "table_schema",
      TRIM(tables.TABNAME) AS "table_name",
      tables.TYPE AS "table_type",
      NULL AS "table_comment",
      TRIM(columns.COLNAME) AS "column_name",
      columns.COLNO AS "column_index",
      columns.TYPENAME AS "column_type",
      NULL AS "column_comment",
      tables.OWNER AS "table_owner"
    FROM tables
    INNER JOIN columns ON
      columns.DATABASE = tables.DATABASE AND
      columns.TABSCHEMA = tables.TABSCHEMA AND
      columns.TABNAME = tables.TABNAME
    WHERE (
        {%- for schema in schemas -%}
          tables.TABSCHEMA = UPPER('{{ schema }}') {%- if not loop.last %} OR {% endif -%}
        {%- endfor -%}
    )
    ORDER BY
      tables.TABSCHEMA,
      tables.TABNAME,
      columns.COLNO

  {%- endcall -%}
  {{ return(load_result('catalog').table) }}
{%- endmacro %}
