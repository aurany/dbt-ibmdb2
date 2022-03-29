{%- materialization view, adapter='ibmdb2' -%}

  {%- set identifier = model['alias'] -%}
  {%- set tmp_identifier = model['name'] + '__dbt_tmp' -%}
  {%- set backup_identifier = model['name'] + '__dbt_backup' -%}

  {%- set old_relation = adapter.get_relation(database=database, schema=schema, identifier=identifier) -%}
  {%- set target_relation = api.Relation.create(identifier=identifier, schema=schema, database=database,
                                                type='view') -%}

  /*
     This relation (probably) doesn't exist yet. If it does exist, it's a leftover from
     a previous run, and we're going to try to drop it immediately. At the end of this
     materialization, we're going to rename the "old_relation" to this identifier,
     and then we're going to drop it. In order to make sure we run the correct one of:
       - drop view ...
       - drop table ...
     We need to set the type of this relation to be the type of the old_relation, if it exists,
     or else "view" as a sane default if it does not. Note that if the old_relation does not
     exist, then there is nothing to move out of the way and subsequentally drop. In that case,
     this relation will be effectively unused.
  */
  {%- set backup_relation_type = 'view' if old_relation is none else old_relation.type -%}
  {%- set backup_relation = api.Relation.create(identifier=backup_identifier,
                                                schema=schema, database=database,
                                                type=backup_relation_type) -%}

  {%- set exists_as_view = (old_relation is not none and old_relation.is_view) -%}

  {{ run_hooks(pre_hooks, inside_transaction=False) }}

  -- drop the temp relations if they exists for some reason
  {{ adapter.drop_relation(backup_relation) }}

  -- `BEGIN` happens here:
  {{ run_hooks(pre_hooks, inside_transaction=True) }}

  -- cleanup
  -- move the existing table out of the way
  {% if old_relation is not none %}
    {% if old_relation.is_view %}
        {{ adapter.drop_relation(old_relation) }}
    {% else %}
        {{ adapter.rename_relation(old_relation, backup_relation) }}
    {% endif %}
  {% endif %}

  -- build model
  {% call statement('main') -%}
    {{ create_view_as(target_relation, sql) }}
  {%- endcall %}

  {% do persist_docs(target_relation, model) %}

  {{ run_hooks(post_hooks, inside_transaction=True) }}

  {# rasmus: moved here before commit #}
  {{ drop_relation_if_exists(backup_relation) }}

  {{ adapter.commit() }}

  {{ run_hooks(post_hooks, inside_transaction=False) }}

  {{ return({'relations': [target_relation]}) }}

{%- endmaterialization -%}