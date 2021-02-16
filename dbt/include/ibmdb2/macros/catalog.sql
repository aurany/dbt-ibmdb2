{% macro ibmdb2__get_catalog(information_schema, schemas) -%}

  {%- call statement('catalog', fetch_result=True) -%}

    WITH columns AS (
      SELECT
        colname,
        typename,
        'testdb' AS database,
        tabname,
        tabschema,
        colno
      FROM syscat.columns
    ),
    tables AS (
      SELECT
        'testdb' AS database,
        tabschema,
        tabname,
        owner,
        CASE
          WHEN type = 'T' THEN 'table'
          WHEN type = 'V' THEN 'view'
        END AS type
      FROM syscat.tables
      WHERE type IN('T', 'V')
    )
    SELECT
      tables.database AS "table_database",
      tables.tabschema AS "table_schema",
      tables.tabname AS "table_name",
      tables.type AS "table_type",
      'blabla' AS "table_comment",
      columns.colname AS "column_name",
      columns.colno AS "column_index",
      columns.typename AS "column_type",
      'blabla' AS "column_comment",
      tables.owner AS "table_owner"
    FROM tables
    INNER JOIN columns ON
      columns.database = tables.DATABASE AND
      columns.tabschema = tables.TABSCHEMA AND
      columns.tabname = tables.TABNAME
    WHERE (
        {%- for schema in schemas -%}
          tables.tabschema = '{{ schema }}' {%- if not loop.last %} OR {% endif -%}
        {%- endfor -%}
    )
    ORDER BY
      tables.tabschema,
      tables.tabname,
      columns.colno

  {%- endcall -%}
  {{ return(load_result('catalog').table) }}
{%- endmacro %}
