{% macro ibmdb2__last_day(date, datepart) -%}

    {%- if datepart == 'quarter' -%}
    	cast(last_day(date_trunc('quarter', {{ date }} ) + 2 months) as date)
    {%- elif datepart == 'month' -%}
        cast(last_day({{ date }}) as date)
    {%- elif datepart == 'year' -%}
        cast(last_day(date_trunc('year', {{ date }} ) + 11 months) as date)
    {%- else -%}
        {{ exceptions.raise_compiler_error("Unsupported datepart for macro last_day in ibmdb2: {!r}".format(datepart)) }}
    {%- endif -%}

{%- endmacro %}
