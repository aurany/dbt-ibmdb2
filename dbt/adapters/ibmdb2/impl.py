from dbt.adapters.sql import SQLAdapter
from dbt.adapters.ibmdb2 import IBMDB2ConnectionManager
from dbt.adapters.ibmdb2.relation import IBMDB2Relation
from dbt.adapters.ibmdb2.column import IBMDB2Column

from typing import Dict
from dbt.utils import filter_null_values
from dbt.exceptions import CompilationError
from dbt.adapters.base.meta import available
from typing import Optional

import agate


class IBMDB2Adapter(SQLAdapter):

    ConnectionManager = IBMDB2ConnectionManager
    Relation = IBMDB2Relation
    Column = IBMDB2Column

    @classmethod
    def date_function(cls):
        return 'CURRENT_DATE'

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

    @available
    def quote_seed_column(self, column: str, quote_config: Optional[bool]) -> str:
        quote_columns: bool = False
        if isinstance(quote_config, bool):
            quote_columns = quote_config
        elif quote_config is None:
            pass
        else:
            raise CompilationError(
                f'The seed configuration value of "quote_columns" has an '
                f"invalid type {type(quote_config)}"
            )

        if quote_columns:
            return self.quote(column)
        else:
            return column

    @classmethod
    def convert_text_type(cls, agate_table, col_idx):
        column = agate_table.columns[col_idx]
        lens = (len(d.encode("utf-8")) for d in column.values_without_nulls())
        max_len = max(lens) if lens else 64
        length = max_len if max_len > 16 else 16
        return "varchar({})".format(length)

    @classmethod
    def convert_date_type(cls, agate_table, col_idx):
        return "timestamp"

    @classmethod
    def convert_datetime_type(cls, agate_table, col_idx):
        return "timestamp"

    @classmethod
    def convert_boolean_type(cls, agate_table, col_idx):
        return "decimal(1)"

    @classmethod
    def convert_number_type(cls, agate_table, col_idx):
        decimals = agate_table.aggregate(agate.MaxPrecision(col_idx))
        return "decimal"

    @classmethod
    def convert_time_type(cls, agate_table, col_idx):
        return "timestamp"

    def valid_incremental_strategies(self):
        """The set of standard builtin strategies which this adapter supports out-of-the-box.
        Not used to validate custom strategies defined by end users.
        """
        # >>> DB2 Note:
        # "delete+insert" and "insert_overwrite" not supported yet
        # <<<
        return ["append", "merge"]