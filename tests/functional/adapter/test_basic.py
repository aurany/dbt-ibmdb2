import pytest

from dbt.tests.adapter.basic.test_adapter_methods import BaseAdapterMethod
from dbt.tests.adapter.basic.test_base import BaseSimpleMaterializations
from dbt.tests.adapter.basic.test_empty import BaseEmpty
from dbt.tests.adapter.basic.test_ephemeral import BaseEphemeral
from dbt.tests.adapter.basic.test_generic_tests import BaseGenericTests
from dbt.tests.adapter.basic.test_incremental import BaseIncremental
from dbt.tests.adapter.basic.test_singular_tests import BaseSingularTests
from dbt.tests.adapter.basic.test_singular_tests_ephemeral import BaseSingularTestsEphemeral
from dbt.tests.adapter.basic.test_snapshot_check_cols import BaseSnapshotCheckCols
from dbt.tests.adapter.basic.test_snapshot_timestamp import BaseSnapshotTimestamp

from dbt.tests.util import (
    run_dbt,
    check_result_nodes_by_name,
    relation_from_name,
    check_relation_types,
    check_relations_equal,
)

from dbt.tests.adapter.basic.files import (
    seeds_base_csv,
    seeds_added_csv,
    seeds_newcolumns_csv,
    base_view_sql,
    base_table_sql,
    base_materialized_var_sql,
    schema_base_yml,
)

schema_seed_yml = """
version: 2
seeds:
  - name: base
    config:
      quote_columns: false
      column_types:
        id: int
        name: varchar(64)
        some_date: timestamp
  - name: added
    config:
      quote_columns: false
      column_types:
        id: int
        name: varchar(64)
        some_date: timestamp
  - name: newcolumns
    config:
      quote_columns: false
      column_types:
        id: int
        name: varchar(64)
        some_date: timestamp
        last_initial: varchar(1)
"""

schema_seed_test_yml = """
version: 2
seeds:
  - name: base
    config:
      quote_columns: false
      column_types:
        id: int
        name: varchar(64)
        some_date: timestamp
    columns:
     - name: id
       tests:
         - not_null
"""

test_passing_sql = """
select * from (
    select 1 as id
    from sysibm.sysdummy1
) as my_subquery
where id = 2
"""

test_failing_sql = """
select * from (
    select 1 as id
    from sysibm.sysdummy1
) as my_subquery
where id = 1
"""


class TestSimpleMaterializationsIBMDB2(BaseSimpleMaterializations):
    @pytest.fixture(scope="class")
    def seeds(self):
        return {
            "base.csv": seeds_base_csv,
            "seeds.yml": schema_seed_yml,
        }

    def test_base(self, project):

        # seed command
        results = run_dbt(["seed"])
        # seed result length
        assert len(results) == 1

        # run command
        results = run_dbt()
        # run result length
        assert len(results) == 3

        # names exist in result nodes
        check_result_nodes_by_name(results, ["view_model", "table_model", "swappable"])

        # check relation types
        expected = {
            "base": "table",
            "view_model": "view",
            "table_model": "table",
            "swappable": "table",
        }
        check_relation_types(project.adapter, expected)

        # base table rowcount
        relation = relation_from_name(project.adapter, "base")
        result = project.run_sql(f"select count(*) as num_rows from {relation}", fetch="one")
        assert result[0] == 10

        # relations_equal
        check_relations_equal(project.adapter, ["base", "view_model", "table_model", "swappable"])

        # check relations in catalog
        catalog = run_dbt(["docs", "generate"])
        assert len(catalog.nodes) == 4
        assert len(catalog.sources) == 1

        # run_dbt changing materialized_var to view
        # results = run_dbt(["run", "-m", "swappable", "--vars", "materialized_var: view"])
        # assert len(results) == 1

        # check relation types, swappable is view
        # expected = {
        #     "base": "table",
        #     "view_model": "view",
        #     "table_model": "table",
        #     "swappable": "view",
        # }
        # check_relation_types(project.adapter, expected)

        # run_dbt changing materialized_var to incremental
        results = run_dbt(["run", "-m", "swappable", "--vars", "materialized_var: incremental"])
        assert len(results) == 1

        # check relation types, swappable is table
        expected = {
            "base": "table",
            "view_model": "view",
            "table_model": "table",
            "swappable": "table",
        }
        check_relation_types(project.adapter, expected)


class TestSingularTestsIBMDB2(BaseSingularTests):
    @pytest.fixture(scope="class")
    def tests(self):
        return {
            "passing.sql": test_passing_sql,
            "failing.sql": test_failing_sql,
        }


class TestSingularTestsEphemeralIBMDB2(BaseSingularTestsEphemeral):
    @pytest.fixture(scope="class")
    def seeds(self):
        return {
            "base.csv": seeds_base_csv,
            "seeds.yml": schema_seed_yml,
        }


class TestEmptyIBMDB2(BaseEmpty):
    pass


class TestEphemeralIBMDB2(BaseEphemeral):
    @pytest.fixture(scope="class")
    def seeds(self):
        return {
            "base.csv": seeds_base_csv,
            "seeds.yml": schema_seed_yml,
        }


class TestIncrementalIBMDB2(BaseIncremental):
    @pytest.fixture(scope="class")
    def seeds(self):
        return {
            "base.csv": seeds_base_csv,
            "added.csv": seeds_added_csv,
            "seeds.yml": schema_seed_yml,
        }


class TestGenericTestsIBMDB2(BaseGenericTests):
    @pytest.fixture(scope="class")
    def seeds(self):
        return {
            "base.csv": seeds_base_csv,
            "seeds.yml": schema_seed_test_yml,
        }



class TestSnapshotCheckColsIBMDB2(BaseSnapshotCheckCols):
    @pytest.fixture(scope="class")
    def seeds(self):
        return {
            "base.csv": seeds_base_csv,
            "added.csv": seeds_added_csv,
            "seeds.yml": schema_seed_yml,
        }


class TestSnapshotTimestampIBMDB2(BaseSnapshotTimestamp):
    @pytest.fixture(scope="class")
    def seeds(self):
        return {
            "base.csv": seeds_base_csv,
            "added.csv": seeds_added_csv,
            "newcolumns.csv": seeds_newcolumns_csv,
            "seeds.yml": schema_seed_yml,
        }


# class TestBaseAdapterMethodIBMDB2(BaseAdapterMethod):
#     pass
