from dataclasses import dataclass
from dbt.adapters.base.relation import BaseRelation, Policy

from typing import Optional, TypeVar, Type
from dbt.contracts.relation import RelationType

Self = TypeVar('Self', bound='BaseRelation')


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

    # DB2 Notes:
    # ----------
    # This fix is only for making the logs look prettier when running without
    # quoting and lowercase schema and identifiers. We force the relations
    # to be created in uppercase letters.
    @classmethod
    def create(
        cls: Type[Self],
        database: Optional[str] = None,
        schema: Optional[str] = None,
        identifier: Optional[str] = None,
        type: Optional[RelationType] = None,
        **kwargs,
    ) -> Self:

        quote_policy = kwargs.get('quote_policy')

        if quote_policy:

            # DB2 Notes:
            # ----------
            # No need to change database to upper. Then database is always created
            # before hand and will always have the same value as in the profiles
            # config because we set it 'manually' in list_relations_without_caching.

            quote_policy_schema = quote_policy.get('schema')
            if quote_policy_schema == False:
                schema = schema.upper()

            quote_policy_identifier = quote_policy.get('identifier')
            if quote_policy_identifier == False:
                identifier = identifier.upper()

        kwargs.update({
            'path': {
                'database': database,
                'schema': schema,
                'identifier': identifier,
            },
            'type': type,
        })

        return cls.from_dict(kwargs)
