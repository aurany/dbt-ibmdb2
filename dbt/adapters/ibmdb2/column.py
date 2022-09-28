from dataclasses import dataclass
from typing import Dict, ClassVar

from dbt.adapters.base.column import Column


@dataclass
class IBMDB2Column(Column):

    TYPE_LABELS: ClassVar[Dict[str, str]] = {
        "STRING": "VARCHAR(4000)",
        "TIMESTAMP": "TIMESTAMP",
        "FLOAT": "DECFLOAT",
        "INTEGER": "INTEGER",
    }

    STRING_DATATYPES = {'char', 'nchar', 'varchar', 'nvarchar'}
    NUMBER_DATATYPES = {'decimal', 'decfloat'}

    @property
    def data_type(self) -> str:
        if self.is_string():
            return self.ibmdb2_string_type(self.dtype, self.string_size())
        elif self.is_numeric():
            return self.numeric_type(self.dtype, self.numeric_precision, self.numeric_scale)
        else:
            return self.dtype

    @classmethod
    def ibmdb2_string_type(cls, dtype: str, size: int = None):
        """
            - CHAR(SIZE)
            - VARCHAR(SIZE)
            - NCHAR(SIZE) or NCHAR
            - NVARCHAR(SIZE)
        """
        if size is None:
            return dtype
        else:
            return "{}({})".format(dtype, size)

    def is_numeric(self) -> bool:
        if self.dtype.lower() in self.NUMBER_DATATYPES:
            return True
        return super().is_numeric()

    def is_string(self) -> bool:
        if self.dtype.lower() in self.STRING_DATATYPES:
            return True
        return super().is_string()
