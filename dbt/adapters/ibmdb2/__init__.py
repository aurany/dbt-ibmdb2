from dbt.adapters.ibmdb2.connections import IBMDB2ConnectionManager
from dbt.adapters.ibmdb2.connections import IBMDB2Credentials
from dbt.adapters.ibmdb2.impl import IBMDB2Adapter

from dbt.adapters.base import AdapterPlugin
from dbt.include import ibmdb2


Plugin = AdapterPlugin(
    adapter=IBMDB2Adapter,
    credentials=IBMDB2Credentials,
    include_path=ibmdb2.PACKAGE_PATH)
