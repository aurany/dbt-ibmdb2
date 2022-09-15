import pytest
import os

from dotenv import load_dotenv
from pathlib import Path

from random import randint

pytest_plugins = ["dbt.tests.fixtures.project"]

dotenv_path = Path('test.env')
load_dotenv(dotenv_path=dotenv_path)

@pytest.fixture(scope="class")
def dbt_profile_target():
    return {
        'type': 'ibmdb2',
        'threads': 1,
        'host': os.getenv('DBT_DB2_HOST'),
        'database': os.getenv('DBT_DB2_DATABASE'),
        'schema': os.getenv('DBT_DB2_SCHEMA'),
        'user': os.getenv('DBT_DB2_USERNAME'),
        'password': os.getenv('DBT_DB2_PASSWORD'),
        'port': int(os.getenv('DBT_DB2_PORT')),
        'protocol': os.getenv('DBT_DB2_PROTOCOL'),
        'extra_connect_opts': os.getenv('DBT_DB2_EXTRA_CONNECT_OPTS'),
    }
