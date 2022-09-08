
{% macro ibmdb2__datediff(first_date, second_date, datepart) %}

    {#
        DB2 dateparts:
        --------------
        1 : Microseconds
        2 : Seconds
        4 : Minutes
        8 : Hours
        16 : Days
        32 : Weeks
        64 : Months
        128 : Quarters of a year
        256 : Years
    #}

    {% if datepart == 'year' %}
        {% set _datepart = 256 %}
    {% elif datepart == 'quarter' %}
        {% set _datepart = 128 %}
    {% elif datepart == 'month' %}
        {% set _datepart = 64 %}
    {% elif datepart == 'day' %}
        {% set _datepart = 16 %}
    {% elif datepart == 'week' %}
        {% set _datepart = 32 %}
    {% elif datepart == 'hour' %}
        {% set _datepart = 8 %}
    {% elif datepart == 'minute' %}
        {% set _datepart = 4 %}
    {% elif datepart == 'second' %}
        {% set _datepart = 2 %}
    {% elif datepart == 'microsecond' %}
        {% set _datepart = 1 %}
    {% else %}
        {{ exceptions.raise_compiler_error("Unsupported datepart for macro datediff in ibmdb2: {!r}".format(datepart)) }}
    {% endif %}

    case when {{ second_date }} is null or {{ first_date }} is null
      then null
      else
      timestampdiff(
          {{ _datepart }},
          char(cast({{ second_date }} as timestamp) - cast({{ first_date }} as timestamp))
      )
    end

{% endmacro %}
