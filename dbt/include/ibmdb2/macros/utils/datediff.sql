
{% macro ibmdb2__datediff(first_date, second_date, datepart) %}

    {#
        DB2 dateparts:
        --------------
        1 : Fractions of a second
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
    {% else %}
        {{ exceptions.raise_compiler_error("Unsupported datepart for macro datediff in ibmdb2: {!r}".format(datepart)) }}
    {% endif %}

    timestampdiff(
        {{ _datepart }},
        char(cast('{{ second_date }}' as datetime) - cast('{{ first_date }}' as datetime))
        )

{% endmacro %}