import pytest

from dbt.tests.adapter.basic.test_docs_generate import (
    models__schema_yml,
    models__readme_md,
    models__model_sql,
    BaseDocsGenerate
)

from dbt.tests.util import AnyInteger
from dbt.tests.adapter.basic.expected_catalog import (
    base_expected_catalog,
    no_stats,
)

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

models__second_model_sql = """
{{
    config(materialized='view')
}}
select * from {{ ref('seed') }}
"""

def base_expected_catalog(
    project,
    role,
    id_type,
    text_type,
    time_type,
    view_type,
    table_type,
    model_stats,
    seed_stats=None,
    case=None,
    case_columns=False,
):

    if case is None:

        def case(x):
            return x

    col_case = case if case_columns else lambda x: x

    if seed_stats is None:
        seed_stats = model_stats

    model_database = case(project.database)
    my_schema_name = case(project.test_schema)
    alternate_schema = case(project.test_schema)

    expected_cols = {
        col_case("id"): {
            "name": col_case("id"),
            "index": AnyInteger(),
            "type": id_type,
            "comment": None,
        },
        col_case("first_name"): {
            "name": col_case("first_name"),
            "index": AnyInteger(),
            "type": text_type,
            "comment": None,
        },
        col_case("email"): {
            "name": col_case("email"),
            "index": AnyInteger(),
            "type": text_type,
            "comment": None,
        },
        col_case("ip_address"): {
            "name": col_case("ip_address"),
            "index": AnyInteger(),
            "type": text_type,
            "comment": None,
        },
        col_case("updated_at"): {
            "name": col_case("updated_at"),
            "index": AnyInteger(),
            "type": time_type,
            "comment": None,
        },
    }
    return {
        "nodes": {
            "model.test.model": {
                "unique_id": "model.test.model",
                "metadata": {
                    "schema": my_schema_name.upper(),
                    "database": model_database.upper(),
                    "name": case("model").upper(),
                    "type": view_type.upper(),
                    "comment": None,
                    "owner": role.upper(),
                },
                "stats": model_stats,
                "columns": expected_cols,
            },
            "model.test.second_model": {
                "unique_id": "model.test.second_model",
                "metadata": {
                    "schema": alternate_schema.upper(),
                    "database": project.database.upper(),
                    "name": case("second_model").upper(),
                    "type": view_type.upper(),
                    "comment": None,
                    "owner": role.upper(),
                },
                "stats": model_stats,
                "columns": expected_cols,
            },
            "seed.test.seed": {
                "unique_id": "seed.test.seed",
                "metadata": {
                    "schema": my_schema_name.upper(),
                    "database": project.database.upper(),
                    "name": case("seed").upper(),
                    "type": table_type.upper(),
                    "comment": None,
                    "owner": role.upper(),
                },
                "stats": seed_stats,
                "columns": expected_cols,
            },
        },
        "sources": {
            "source.test.my_source.my_table": {
                "unique_id": "source.test.my_source.my_table",
                "metadata": {
                    "schema": my_schema_name.upper(),
                    "database": project.database.upper(),
                    "name": case("seed").upper(),
                    "type": table_type.upper(),
                    "comment": None,
                    "owner": role.upper(),
                },
                "stats": seed_stats,
                "columns": expected_cols,
            },
        },
    }

class TestDocsGenerateIBMDB2(BaseDocsGenerate):
    @pytest.fixture(scope="class")
    def seeds(self):
        return {
            "seed.csv": seed__seed_csv,
            "schema.yml": seed__schema_yml,
        }

    @pytest.fixture(scope="class")
    def models(self):
        return {
            "schema.yml": models__schema_yml,
            "second_model.sql": models__second_model_sql,
            "readme.md": models__readme_md,
            "model.sql": models__model_sql,
        }

    @pytest.fixture(scope="class")
    def expected_catalog(self, project, profile_user):
        return base_expected_catalog(
            project,
            role=profile_user,
            id_type="INTEGER",
            text_type="VARCHAR",
            time_type="TIMESTAMP",
            view_type="VIEW",
            table_type="TABLE",
            model_stats=no_stats(),
            case=lambda x: x.upper(),
            case_columns=True
        )
