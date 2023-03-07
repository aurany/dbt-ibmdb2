import pytest
from dbt.tests.adapter.utils.test_timestamps import BaseCurrentTimestamps

_MODEL_CURRENT_TIMESTAMP = """
select {{ current_timestamp() }} as current_timestamp,
       {{ current_timestamp_in_utc_backcompat() }} as current_timestamp_in_utc_backcompat,
       {{ current_timestamp_backcompat() }} as current_timestamp_backcompat
from sysibm.sysdummy1
"""

class TestCurrentTimestampIBMDB2(BaseCurrentTimestamps):
    @pytest.fixture(scope="class")
    def models(self):
        return {"get_current_timestamp.sql": _MODEL_CURRENT_TIMESTAMP}

    @pytest.fixture(scope="class")
    def expected_schema(self):
        return {
            "CURRENT_TIMESTAMP": "TIMESTAMP",
            "CURRENT_TIMESTAMP_IN_UTC_BACKCOMPAT": "TIMESTAMP",
            "CURRENT_TIMESTAMP_BACKCOMPAT": "TIMESTAMP",
        }

    @pytest.fixture(scope="class")
    def expected_sql(self):
        return """select CURRENT TIMESTAMP as current_timestamp,
                CURRENT TIMESTAMP - CURRENT TIMEZONE as current_timestamp_in_utc_backcompat,
                CURRENT TIMESTAMP as current_timestamp_backcompat
                from sysibm.sysdummy1"""
