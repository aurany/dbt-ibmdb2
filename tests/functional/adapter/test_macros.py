import pytest

from dbt.tests.adapter.utils.test_hash import BaseHash
from dbt.tests.adapter.utils.test_position import BasePosition
from dbt.tests.adapter.utils.test_dateadd import BaseDateAdd
from dbt.tests.adapter.utils.test_last_day import BaseLastDay
from dbt.tests.adapter.utils.test_datediff import BaseDateDiff
from dbt.tests.adapter.utils.test_split_part import BaseSplitPart
from dbt.tests.adapter.utils.data_types.test_type_string import BaseTypeString

seeds__data_hash_csv = """input_1,output
ab,187EF4436122D1CC2F40DC2B92F0EBA0
a,0CC175B9C0F1B6A831C399E269772661
1,C4CA4238A0B923820DCC509A6F75849B
,D41D8CD98F00B204E9800998ECF8427E
"""

seeds__schema_hash_yml = """
version: 2
seeds:
  - name: data_hash
    config:
      quote_columns: false
      column_types:
        input_1: varchar(256)
        output: varchar(256)
"""

seeds__data_position_csv = """substring_text,string_text,result
def,abcdef,4
land,earth,0
town,fishtown,5
ember,december,4
"""

seeds__schema_position_yml = """
version: 2
seeds:
  - name: data_position
    config:
      quote_columns: false
      column_types:
        substring_text: varchar(256)
        string_text: varchar(256)
        result: int
"""

seeds__data_last_day_csv = """date_day,date_part,result
2018-01-02,month,2018-01-31
2018-01-02,quarter,2018-03-31
2018-01-02,year,2018-12-31
,month,
"""

seeds__schema_last_day_yml = """
version: 2
seeds:
  - name: data_last_day
    config:
      quote_columns: false
      column_types:
        date_day: date
        date_part: varchar(16)
        result: date
"""

seeds__data_type_string_csv = """string_col
"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
""".lstrip()

seeds__schema_type_string_yml = """
version: 2
seeds:
  - name: expected
    config:
      quote_columns: false
      column_types:
        string_col: varchar(1000)
"""

models__type_string_actual_sql = """
select cast('Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'
as {{ type_string() }}(1000) ) as string_col
from sysibm.sysdummy1
"""

seeds__data_split_part_csv = """parts,split_on,result_1,result_2,result_3
a|b|c,|,a,b,c
1|2|3,|,1,2,3
,|,,,
"""

seeds__schema_split_part_yml = """
version: 2
seeds:
  - name: data_split_part
    config:
      quote_columns: false
      column_types:
        parts: varchar(10)
        split_on: varchar(10)
        result_1: varchar(10)
        result_2: varchar(10)
        result_3: varchar(10)
"""

# class TestHashIBMDB2(BaseHash):
#     @pytest.fixture(scope="class")
#     def seeds(self):
#         return {
#             "data_hash.csv": seeds__data_hash_csv,
#             "data_hash.yml": seeds__schema_hash_yml,
#         }
#
# class TestPositionIBMDB2(BasePosition):
#     @pytest.fixture(scope="class")
#     def seeds(self):
#         return {
#             "data_position.csv": seeds__data_position_csv,
#             "data_position.yml": seeds__schema_position_yml,
#         }
#
# class TestLastDayIBMDB2(BaseLastDay):
#     @pytest.fixture(scope="class")
#     def seeds(self):
#         return {
#             "data_last_day.csv": seeds__data_last_day_csv,
#             "data_last_day.yml": seeds__schema_last_day_yml,
#         }

# class TestTypeStringIBMDB2(BaseTypeString):
#     @pytest.fixture(scope="class")
#     def seeds(self):
#         return {
#             "expected.csv": seeds__data_type_string_csv,
#             "expected.yml": seeds__schema_type_string_csv,
#         }
#
#     @pytest.fixture(scope="class")
#     def models(self):
#         return {"actual.sql": self.interpolate_macro_namespace(models__type_string_actual_sql, "type_string")}

# class TestSplitPartIBMDB2(BaseSplitPart):
#     @pytest.fixture(scope="class")
#     def seeds(self):
#         return {
#             "data_split_part.csv": seeds__data_split_part_csv,
#             "data_split_part.yml": seeds__schema_split_part_yml,
#         }

#class TestDateAdd(BaseDateAdd):
    #pass
    # @pytest.fixture(scope="class")
    # def seeds(self):
    #     return {"data_dateadd.csv": seeds__data_dateadd_csv}
    #
    # @pytest.fixture(scope="class")
    # def models(self):
    #     return {
    #         "test_dateadd.yml": models__test_dateadd_yml,
    #         "test_dateadd.sql": self.interpolate_macro_namespace(
    #             models__test_dateadd_sql, "dateadd"
    #         ),
    #     }

#class TestDateDiff(BaseDateDiff):
    #pass
    # @pytest.fixture(scope="class")
    # def seeds(self):
    #     return {"data_datediff.csv": seeds__data_datediff_csv}
    #
    # @pytest.fixture(scope="class")
    # def models(self):
    #     return {
    #         "test_datediff.yml": models__test_datediff_yml,
    #         "test_datediff.sql": self.interpolate_macro_namespace(
    #             models__test_datediff_sql, "datediff"
    #         ),
    #     }
