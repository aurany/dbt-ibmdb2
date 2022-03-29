[![pypi](https://badge.fury.io/py/dbt-ibmdb2.svg)](https://pypi.org/project/dbt-ibmdb2/)
[![python](https://img.shields.io/pypi/pyversions/dbt-ibmdb2)](https://pypi.org/project/dbt-ibmdb2/)

# dbt-ibmdb2

This plugin ports [dbt](https://getdbt.com) functionality to IBM DB2.

This is an experimental plugin:
- We have not tested it extensively
- Tested with [dbt-adapter-tests](https://pypi.org/project/pytest-dbt-adapter/) and DB2 LUW on Mac OS+RHEL8
- Compatiblity with other [dbt packages](https://hub.getdbt.com/) (like [dbt_utils](https://hub.getdbt.com/fishtown-analytics/dbt_utils/latest/)) is only partially tested

Please read these docs carefully and use at your own risk. [Issues](https://github.com/aurany/dbt-ibmdb2/issues/new) welcome!

**TODO**
- [ ] Implement support for quoting on tables and schemas
- [ ] Check compatibility with DB2 for z/OS

Table of Contents
=================

   * [Installation](#installation)
   * [Supported features](#supported-features)
   * [Configuring your profile](#configuring-your-profile)
   * [Notes](#notes)
   * [Running Tests](#running-tests)
   * [Reporting bugs](#reporting-bugs)

### Installation
This plugin can be installed via pip:

```bash
$ pip install dbt-ibmdb2
```

### Supported features

| DB2 LUW | DB2 z/OS | Feature |
|:---------:|:---:|---------------------|
| ✅ | 🤷 | Table materialization       |
| ✅ | 🤷 | View materialization        |
| ✅ | 🤷 | Incremental materialization |
| ✅ | 🤷 | Ephemeral materialization   |
| ✅ | 🤷 | Seeds                       |
| ✅ | 🤷 | Sources                     |
| ✅ | 🤷 | Custom data tests           |
| ✅ | 🤷 | Docs generate               |
| ✅ | 🤷 | Snapshots                   |

Notes:
- dbt-ibmdb2 is built on the ibm_db python package and there are some known encoding issues related to z/OS.

### Configuring your profile

A dbt profile can be configured to run against DB2 using the following configuration example:

**Example entry for profiles.yml:**

```
your_profile_name:
  target: dev
  outputs:
    dev:
      type: ibmdb2
      schema: analytics
      database: test
      host: localhost
      port: 50000
      protocol: TCPIP
      username: my_username
      password: my_password
```

| Option          | Description                                                                         | Required?                                                          | Example                                        |
| --------------- | ----------------------------------------------------------------------------------- | ------------------------------------------------------------------ | ---------------------------------------------- |
| type            | The specific adapter to use                                                         | Required                                                           | `ibmdb2`                                       |
| schema          | Specify the schema (database) to build models into                                  | Required                                                           | `analytics`                                    |
| database        | Specify the database you want to connect to                                         | Required                                                           | `testdb`                                         |
| host            | Hostname or IP-adress                                                               | Required                                                           | `localhost`                                    |
| port            | The port to use                                                                     | Optional                                                           | `50000`                                        |
| protocol        | Protocol to use                                                                     | Optional                                                           | `TCPIP`                                        |
| username        | The username to use to connect to the server                                        | Required                                                           | `my-username`                                  |
| password        | The password to use for authenticating to the server                                | Required                                                           | `my-password`                                  |

### Running Tests

See [test/README.md](test/README.md) for details on running the integration tests.

### Reporting bugs

Want to report a bug or request a feature? Open [an issue](https://github.com/aurany/dbt-ibmdb2/issues/new).

### Credits

dbt-ibmdb2 is heavily inspired by and borrows from [dbt-mysql](https://github.com/dbeatty10/dbt-mysql) and [dbt-oracle](https://github.com/techindicium/dbt-oracle).
