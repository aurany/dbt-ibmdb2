{% macro oracle__get_catalog(information_schema, schemas) -%}

  {%- call statement('catalog', fetch_result=True) -%}

    with columns as (
      select
        COLNAME,
        TYPENAME,
        'testdb' AS DATABASE
        TABNAME,
        TABSCHEMA
      from syscat.columns
    ),
    tables as (
      select
        'testdb' as DATABASE,
        TABSCHEMA,
        TABNAME,
        OWNER,
        case
          when TYPE = 'T' then 'table'
          when TYPE = 'V' then 'view'
        end as TYPE
      from syscat.tables
      where TYPE in ('T', 'V')
    )
    select
      tables.DATABASE as "table_database",
      tables.TABSCHEMA as "table_schema",
      tables.TABNAME as "table_name",
      tables.TYPE as "table_type",
      'blabla' as "table_comment",
      columns.COLNAME as "column_name",
      columns.COLNO as "column_index",
      columns.TYPENAME as "column_type",
      'blabla' as "column_comment",
      tables.OWNER as "table_owner"
    from tables
    inner join columns on
      columns.DATABASE = tables.DATABASE and
      columns.TABSCHEMA = tables.TABSCHEMA and
      columns.TABNAME = tables.TABNAME
    where (
        {%- for schema in schemas -%}
          tables.TABSCHEMA = '{{ schema }}' {%- if not loop.last %} or {% endif -%}
        {%- endfor -%}
    )
    order by
      TABSCHEMA,
      TABNAME,
      COLNO

  {%- endcall -%}
  {{ return(load_result('catalog').table) }}
{%- endmacro %}
