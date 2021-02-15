from dbt.adapters.sql import SQLAdapter
from dbt.adapters.ibmdb2 import IBMDB2ConnectionManager
from dbt.adapters.ibmdb2.relation import IBMDB2Relation


class IBMDB2Adapter(SQLAdapter):
    ConnectionManager = IBMDB2ConnectionManager
    Relation = IBMDB2Relation

    @classmethod
    def date_function(cls):
        return 'datenow()'

    def is_cancelable(cls):
        return False

    def debug_query(self):
        self.execute('select 1 as one from sysibm.sysdummy1')
