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

seeds__data_dateadd_csv = """from_time,interval_length,datepart,result
2018-01-01 01:00:00,1,day,2018-01-02 01:00:00
2018-01-01 01:00:00,1,month,2018-02-01 01:00:00
2018-01-01 01:00:00,1,year,2019-01-01 01:00:00
2018-01-01 01:00:00,1,hour,2018-01-01 02:00:00
,1,day,
"""

seeds__schema_dateadd_yml = """
version: 2
seeds:
  - name: data_dateadd
    config:
      quote_columns: false
      column_types:
        from_time: datetime
        interval_length: int
        datepart: varchar(10)
        result: datetime
"""

models__test_dateadd_sql = """
with data as (
    select * from {{ ref('data_dateadd') }}
)
select
    case
        when datepart = 'hour' then cast({{ dateadd('hour', 'interval_length', 'from_time') }} as {{ api.Column.translate_type('timestamp') }})
        when datepart = 'day' then cast({{ dateadd('day', 'interval_length', 'from_time') }} as {{ api.Column.translate_type('timestamp') }})
        when datepart = 'month' then cast({{ dateadd('month', 'interval_length', 'from_time') }} as {{ api.Column.translate_type('timestamp') }})
        when datepart = 'year' then cast({{ dateadd('year', 'interval_length', 'from_time') }} as {{ api.Column.translate_type('timestamp') }})
        else null
    end as actual,
    result as expected
from data
"""

seeds__data_datediff_csv = """first_date,second_date,datepart,result
2018-01-01 01:00:00,2018-01-02 01:00:00,day,1
2018-01-01 01:00:00,2018-02-01 01:00:00,month,1
2018-01-01 01:00:00,2019-01-01 01:00:00,year,1
2018-01-01 01:00:00,2018-01-01 02:00:00,hour,1
2018-01-01 01:00:00,2018-01-01 02:01:00,minute,61
2018-01-01 01:00:00,2018-01-01 02:00:01,second,3601
2019-12-31 00:00:00,2019-12-30 00:00:00,week,0
2019-12-31 00:00:00,2020-01-02 00:00:00,week,0
2019-12-31 00:00:00,2020-01-08 02:00:00,week,1
2019-12-31 00:00:00,2019-12-22 00:00:00,week,-1
,2018-01-01 02:00:00,hour,
2018-01-01 02:00:00,,hour,
"""

seeds__schema_datediff_yml = """
version: 2
seeds:
  - name: data_datediff
    config:
      quote_columns: false
      column_types:
        first_date: datetime
        second_date: datetime
        datepart: varchar(10)
        result: int
"""

models__test_datediff_sql = """
with data as (
    select * from {{ ref('data_datediff') }}
)
select
    case
        when datepart = 'second' then {{ datediff('FIRST_DATE', 'SECOND_DATE', 'second') }}
        when datepart = 'minute' then {{ datediff('FIRST_DATE', 'SECOND_DATE', 'minute') }}
        when datepart = 'hour' then {{ datediff('FIRST_DATE', 'SECOND_DATE', 'hour') }}
        when datepart = 'day' then {{ datediff('FIRST_DATE', 'SECOND_DATE', 'day') }}
        when datepart = 'week' then {{ datediff('FIRST_DATE', 'SECOND_DATE', 'week') }}
        when datepart = 'month' then {{ datediff('FIRST_DATE', 'SECOND_DATE', 'month') }}
        when datepart = 'year' then {{ datediff('FIRST_DATE', 'SECOND_DATE', 'year') }}
        else null
    end as actual,
    result as expected
from data
-- Also test correct casting of literal values.
union all select {{ datediff("'1999-12-31 23:59:59.999999'", "'2000-01-01 00:00:00.000000'", "microsecond") }} as actual, 1 as expected from sysibm.sysdummy1
union all select {{ datediff("'1999-12-31 23:59:59.000000'", "'2000-01-01 00:00:00.000000'", "second") }} as actual, 1 as expected from sysibm.sysdummy1
union all select {{ datediff("'1999-12-31 23:59:00.000000'", "'2000-01-01 00:00:00.000000'", "minute") }} as actual, 1 as expected from sysibm.sysdummy1
union all select {{ datediff("'1999-12-31 23:00:00.000000'", "'2000-01-01 00:00:00.000000'", "hour") }} as actual, 1 as expected from sysibm.sysdummy1
union all select {{ datediff("'1999-12-31 00:00:00.000000'", "'2000-01-01 00:00:00.000000'", "day") }} as actual, 1 as expected from sysibm.sysdummy1
union all select {{ datediff("'1999-12-26 00:00:00.000000'", "'2000-01-03 00:00:00.000000'", "week") }} as actual, 1 as expected from sysibm.sysdummy1
union all select {{ datediff("'1999-12-01 00:00:00.000000'", "'2000-01-01 00:00:00.000000'", "month") }} as actual, 1 as expected from sysibm.sysdummy1
union all select {{ datediff("'1999-10-01 00:00:00.000000'", "'2000-01-01 00:00:00.000000'", "quarter") }} as actual, 1 as expected from sysibm.sysdummy1
union all select {{ datediff("'1999-01-01 00:00:00.000000'", "'2000-01-01 00:00:00.000000'", "year") }} as actual, 1 as expected from sysibm.sysdummy1
"""

models__test_datediff_yml = """
version: 2
models:
  - name: test_datediff
    tests:
      - assert_equal:
          actual: actual
          expected: expected
"""

class TestHashIBMDB2(BaseHash):
    @pytest.fixture(scope="class")
    def seeds(self):
        return {
            "data_hash.csv": seeds__data_hash_csv,
            "data_hash.yml": seeds__schema_hash_yml,
        }

class TestPositionIBMDB2(BasePosition):
    @pytest.fixture(scope="class")
    def seeds(self):
        return {
            "data_position.csv": seeds__data_position_csv,
            "data_position.yml": seeds__schema_position_yml,
        }

class TestLastDayIBMDB2(BaseLastDay):
    @pytest.fixture(scope="class")
    def seeds(self):
        return {
            "data_last_day.csv": seeds__data_last_day_csv,
            "data_last_day.yml": seeds__schema_last_day_yml,
        }

class TestTypeStringIBMDB2(BaseTypeString):
    @pytest.fixture(scope="class")
    def seeds(self):
        return {
            "expected.csv": seeds__data_type_string_csv,
            "expected.yml": seeds__schema_type_string_yml,
        }

    @pytest.fixture(scope="class")
    def models(self):
        return {"actual.sql": self.interpolate_macro_namespace(models__type_string_actual_sql, "type_string")}

class TestSplitPartIBMDB2(BaseSplitPart):
    @pytest.fixture(scope="class")
    def seeds(self):
        return {
            "data_split_part.csv": seeds__data_split_part_csv,
            "data_split_part.yml": seeds__schema_split_part_yml,
        }

class TestDateAdd(BaseDateAdd):
    pass
    @pytest.fixture(scope="class")
    def seeds(self):
        return {"data_dateadd.csv": seeds__data_dateadd_csv}

    @pytest.fixture(scope="class")
    def models(self):
        return {
            "test_dateadd.csv": seeds__data_dateadd_csv,
            "test_dateadd.yml": seeds__schema_dateadd_yml,
            "test_dateadd.sql": self.interpolate_macro_namespace(
                models__test_dateadd_sql, "dateadd"
            ),
        }

class TestDateDiff(BaseDateDiff):
    pass
    @pytest.fixture(scope="class")
    def seeds(self):
        return {
            "data_datediff.csv": seeds__data_datediff_csv,
            "data_datediff.yml": seeds__schema_datediff_yml,
        }

    @pytest.fixture(scope="class")
    def models(self):
        return {
            "test_datediff.yml": models__test_datediff_yml,
            "test_datediff.sql": self.interpolate_macro_namespace(
                models__test_datediff_sql, "datediff"
            ),
        }
