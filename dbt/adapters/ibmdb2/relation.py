from dataclasses import dataclass
from dbt.adapters.base.relation import BaseRelation, Policy


@dataclass
class IBMDB2QuotePolicy(Policy):
    database: bool = False
    schema: bool = False
    identifier: bool = False


@dataclass
class IBMDB2IncludePolicy(Policy):
    database: bool = False
    schema: bool = True
    identifier: bool = True


@dataclass(frozen=True, eq=False, repr=False)
class IBMDB2Relation(BaseRelation):
    quote_policy: IBMDB2QuotePolicy = IBMDB2QuotePolicy()
    include_policy: IBMDB2IncludePolicy = IBMDB2IncludePolicy()

    @staticmethod
    def add_ephemeral_prefix(name: str):
        return f'DBT_CTE__{name}'
