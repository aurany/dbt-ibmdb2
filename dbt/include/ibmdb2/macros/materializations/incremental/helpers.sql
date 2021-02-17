{% macro ibmdb2_incremental_upsert(tmp_relation, target_relation, unique_key=none, statement_name="main") %}
    {%- set dest_columns = adapter.get_columns_in_relation(target_relation) -%}
    {%- set dest_cols_csv = dest_columns | map(attribute='name') | join(', ') -%}

    {%- if unique_key is not none -%}
    MERGE INTO {{ target_relation }} target
      USING {{ tmp_relation }} temp
      ON (temp.{{ unique_key }} = target.{{ unique_key }})
    WHEN MATCHED THEN
      UPDATE SET
      {% for col in dest_columns if col.name != unique_key %}
        target.{{ col.name }} = temp.{{ col.name }}
        {% if not loop.last %}, {% endif %}
      {% endfor %}
    WHEN NOT MATCHED THEN
      INSERT( {{ dest_cols_csv }} )
      VALUES(
        {% for col in dest_columns %}
          temp.{{ col.name }}
          {% if not loop.last %}, {% endif %}
        {% endfor %}
      )
    {%- else %}
    INSERT INTO {{ target_relation }} ({{ dest_cols_csv }})
    (
       SELECT {{ dest_cols_csv }}
       FROM {{ tmp_relation }}
    )
    {% endif %}
{%- endmacro %}
