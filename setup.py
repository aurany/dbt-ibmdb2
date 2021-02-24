#!/usr/bin/env python
from setuptools import find_packages
from setuptools import setup

package_name = "dbt-ibmdb2"
package_version = "0.1.0"
description = """The db2 adapter plugin for dbt (data build tool)"""

setup(
    name=package_name,
    version=package_version,
    description=description,
    long_description=description,
    author="Rasmus Nyberg",
    author_email="rasmus.nyberg@gmail.com",
    url="https://github.com/aurany",
    packages=find_packages(),
    package_data={
        'dbt': [
            'include/ibmdb2/macros/*.sql',
            'include/ibmdb2/dbt_project.yml',
        ]
    },
    install_requires=[
        'dbt-core==0.19.0',
        "ibm-db==3.0.2",
    ]
)
