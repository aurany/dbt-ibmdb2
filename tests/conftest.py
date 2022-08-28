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
        'port': int(os.getenv('DBT_DB2_PORT')),
        'schema': os.getenv('DBT_DB2_SCHEMA'),
        'protocol': os.getenv('DBT_DB2_PROTOCOL'),
        'username': os.getenv('DBT_DB2_USERNAME'),
        'password': os.getenv('DBT_DB2_PASSWORD'),
        'database': os.getenv('DBT_DB2_DATABASE'),
    }
