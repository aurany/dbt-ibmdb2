import pytest
import os
from dbt.tests.util import run_dbt, relation_from_name


seed__schema_yml = """
version: 2
seeds:
  - name: test_large_seed
    config:
      quote_columns: false
      column_types:
        id: int
        name: varchar(64)
        value: varchar(64)
"""

# Sample SQL to test the batch size.
test_batch_size_sql = """
SELECT * FROM {{ ref('test_large_seed') }} LIMIT {{ get_batch_size() }}
"""


class TestBatchSizeIBMDB2:
    @property
    def models(self):
        return "models"

    @pytest.fixture(scope="class")
    def seeds(self):
        current_dir = os.path.dirname(os.path.abspath(__file__))
        seed_data_file = os.path.join(current_dir, "test_data", "test_large_seed.csv")
        with open(seed_data_file, "r", newline="") as file:
            test_large_seed_csv = file.read()
        return {
            "test_large_seed.csv": test_large_seed_csv,
            "schema.yml": seed__schema_yml,
        }

    @pytest.fixture(scope="class")
    def batch_size_test(self):
        return {
            "test_batch_size.sql": test_batch_size_sql,
        }

    @pytest.mark.parametrize("custom,BATCH_SIZE", [(True, 200), (False, 1000)])
    def test_get_batch_size_macro(self, project, batch_size_test, custom, BATCH_SIZE):
        results = run_dbt(["seed"])

        model_path = os.path.join(self.models, "test_batch_size.sql")
        with open(model_path, "w") as f:
            f.write(batch_size_test["test_batch_size.sql"])

        dbt_command_list = [
            "run",
            "-m",
            "test_batch_size",
        ]
        if custom:
            dbt_command_list += ["--vars", f"ibmdb2_batch_size: {BATCH_SIZE}"]

        results = run_dbt(dbt_command_list)
        assert len(results) == 1

        # Check the number of rows returned by the query
        relation = relation_from_name(project.adapter, "test_batch_size")
        result = project.run_sql(
            f"select count(*) as num_rows from {relation}", fetch="one"
        )
        assert (
            result[0] == BATCH_SIZE
        ), f"Expected {BATCH_SIZE} rows but got {result[0]}"
