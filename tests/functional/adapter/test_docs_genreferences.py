import pytest
import os
from datetime import datetime
import dbt


from dbt.tests.util import run_dbt, rm_file, get_artifact, check_datetime_between

from dbt.tests.adapter.basic.test_docs_generate import (BaseDocsGenReferences,
                                                        ref_models__schema_yml,
                                                        ref_sources__schema_yml,
                                                        ref_models__ephemeral_copy_sql,
                                                        ref_models__docs_md)

from dbt.tests.adapter.basic.expected_catalog import no_stats

ref_sources__schema_yml = """
version: 2
sources:
  - name: my_source
    description: "{{ doc('source_info') }}"
    loader: a_loader
    schema: "{{ var('test_schema') }}"
    quoting:
      database: False
      identifier: False
    tables:
      - name: my_table
        description: "{{ doc('table_info') }}"
        identifier: seed
        quoting:
          identifier: False
        columns:
          - name: id
            description: "{{ doc('column_info') }}"
"""

seed__schema_yml = """
version: 2
seeds:
  - name: seed
    config:
      quote_columns: false
      column_types:
        id: int
        first_name: varchar(64)
        email: varchar(256)
        ip_address: varchar(32)
        updated_at: timestamp
"""

seed__seed_csv = """id,first_name,email,ip_address,updated_at
1,Larry,lking0@miitbeian.gov.cn,69.135.206.194,2008-09-12 19:08:31
"""

# Override/remove quoting of columns (select 'first_name', ...)
ref_models__ephemeral_summary_sql = """
{{
  config(
    materialized = "table"
  )
}}

select first_name, count(*) as ct
from {{ ref('ephemeral_copy') }}
group by first_name
order by first_name asc
"""

# Override/remove 'order by ct asc'
ref_models__view_summary_sql = """
{{
  config(
    materialized = "view"
  )
}}

select first_name, ct from {{ref('ephemeral_summary')}}
"""

class TextType:

    def __eq__(self, other):
        return other.upper().startswith('VARCHAR')

def expected_references_catalog(
    project,
    role,
    id_type,
    text_type,
    time_type,
    view_type,
    table_type,
    model_stats,
    bigint_type=None,
    seed_stats=None,
    case=lambda x: x.upper(),
    case_columns=True,
    view_summary_stats=None
):
    if case is None:

        def case(x):
            return x

    col_case = case if case_columns else lambda x: x

    if seed_stats is None:
        seed_stats = model_stats

    if view_summary_stats is None:
        view_summary_stats = model_stats

    model_database = project.database.upper()
    my_schema_name = project.test_schema.upper()

    summary_columns = {
        "FIRST_NAME": {
            "name": "FIRST_NAME",
            "index": 0,
            "type": TextType() ,
            "comment": None,
        },
        "CT": {
            "name": "CT",
            "index": 1,
            "type": bigint_type,
            "comment": None,
        },
    }

    seed_columns = {
        "ID": {
            "name": col_case("ID"),
            "index": 0,
            "type": id_type,
            "comment": None,
        },
        "FIRST_NAME": {
            "name": col_case("FIRST_NAME"),
            "index": 1,
            "type": TextType(),
            "comment": None,
        },
        "EMAIL": {
            "name": col_case("EMAIL"),
            "index": 2,
            "type": TextType(),
            "comment": None,
        },
        "IP_ADDRESS": {
            "name": col_case("IP_ADDRESS"),
            "index": 3,
            "type": TextType(),
            "comment": None,
        },
        "UPDATED_AT": {
            "name": col_case("UPDATED_AT"),
            "index": 4,
            "type": time_type,
            "comment": None,
        },
    }
    return {
        "nodes": {
            "seed.test.seed": {
                "unique_id": "seed.test.seed",
                "metadata": {
                    "schema": my_schema_name,
                    "database": project.database.upper(),
                    "name": case("seed").upper(),
                    "type": table_type,
                    "comment": None,
                    "owner": role,
                },
                "stats": seed_stats,
                "columns": seed_columns,
            },
            "model.test.ephemeral_summary": {
                "unique_id": "model.test.ephemeral_summary",
                "metadata": {
                    "schema": my_schema_name,
                    "database": model_database,
                    "name": case("ephemeral_summary").upper(),
                    "type": table_type,
                    "comment": None,
                    "owner": role,
                },
                "stats": model_stats,
                "columns": summary_columns,
            },
            "model.test.view_summary": {
                "unique_id": "model.test.view_summary",
                "metadata": {
                    "schema": my_schema_name,
                    "database": model_database,
                    "name": case("view_summary").upper(),
                    "type": view_type,
                    "comment": None,
                    "owner": role,
                },
                "stats": view_summary_stats,
                "columns": summary_columns,
            },
        },
        "sources": {
            "source.test.my_source.my_table": {
                "unique_id": "source.test.my_source.my_table",
                "metadata": {
                    "schema": my_schema_name,
                    "database": project.database.upper(),
                    "name": case("seed").upper(),
                    "type": table_type,
                    "comment": None,
                    "owner": role,
                },
                "stats": seed_stats,
                "columns": seed_columns,
            },
        },
    }


class TestDocsGenReferencesIBMDB2(BaseDocsGenReferences):

    @pytest.fixture(scope="class")
    def seeds(self):
        return {
            "seed.csv": seed__seed_csv,
            "schema.yml": seed__schema_yml,
        }

    @pytest.fixture(scope="class")
    def models(self):
        return {
            "schema.yml": ref_models__schema_yml,
            "sources.yml": ref_sources__schema_yml,
            "view_summary.sql": ref_models__view_summary_sql,
            "ephemeral_summary.sql": ref_models__ephemeral_summary_sql,
            "ephemeral_copy.sql": ref_models__ephemeral_copy_sql,
            "docs.md": ref_models__docs_md,
        }

    @pytest.fixture(scope="class")
    def expected_catalog(self, project, profile_user):
        return expected_references_catalog(
            project,
            role=profile_user.upper(),
            id_type="INTEGER",
            text_type="VARCHAR",
            time_type="TIMESTAMP",
            bigint_type="INTEGER",
            view_type="VIEW",
            table_type="TABLE",
            model_stats=no_stats(),
            case_columns=False
        )
