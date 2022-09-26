from dbt.adapters.sql import SQLAdapter
from dbt.adapters.ibmdb2 import IBMDB2ConnectionManager
from dbt.adapters.ibmdb2.relation import IBMDB2Relation

from typing import Dict
from dbt.utils import filter_null_values


class IBMDB2Adapter(SQLAdapter):
    ConnectionManager = IBMDB2ConnectionManager
    Relation = IBMDB2Relation

    @classmethod
    def date_function(cls):
        return 'datenow()'

    def is_cancelable(cls):
        return False

    # Notes: DB2 always need a FROM
    def debug_query(self):
        self.execute('select 1 as one from sysibm.sysdummy1')

    # DB2 Notes:
    # ----------
    # To allow for none quoting and keep lowercase naming of schema (in profiles)
    # and identifiers (models via filenames) we need to modify the search params,
    # otherwise dbt will search for lowercase and find uppercase which will lead
    # to exceptions.
    def _make_match_kwargs(self, database: str, schema: str, identifier: str) -> Dict[str, str]:
        quoting = self.config.quoting

        if identifier is not None and quoting["identifier"] is False:
            identifier = identifier.upper()

        if schema is not None and quoting["schema"] is False:
            schema = schema.upper()

        # DB2 Notes:
        # ----------
        # No need to change database to upper. Then database is always created
        # before hand and will always have the same value as in the profiles
        # config because we set it 'manually' in list_relations_without_caching.

        #if database is not None and quoting["database"] is False:
        #    database = database.upper()

        return filter_null_values(
            {
                "database": database,
                "identifier": identifier,
                "schema": schema,
            }
        )
