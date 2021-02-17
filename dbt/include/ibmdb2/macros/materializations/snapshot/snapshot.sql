
{% macro build_snapshot_staging_table(strategy, sql, target_relation) %}
    {% set tmp_relation = make_temp_relation(target_relation) %}

    {% set select = snapshot_staging_table(strategy, sql, target_relation) %}

    {% do adapter.drop_relation(tmp_relation) %}

    {% call statement('build_snapshot_staging_relation') %}
        {{ create_table_as(True, tmp_relation, select) }}
    {% endcall %}

    {% do return(tmp_relation) %}
{% endmacro %}
