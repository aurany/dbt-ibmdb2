[![pypi](https://badge.fury.io/py/dbt-ibmdb2.svg)](https://pypi.org/project/dbt-ibmdb2/)
[![python](https://img.shields.io/pypi/pyversions/dbt-ibmdb2)](https://pypi.org/project/dbt-ibmdb2/)

# dbt-ibmdb2

This plugin ports [dbt](https://getdbt.com) functionality to IBM DB2.

This is an experimental plugin:
- We have not tested it extensively
- Only basic tests are implemented
- Compatibility with other [dbt packages](https://hub.getdbt.com/) (like [dbt_utils](https://hub.getdbt.com/fishtown-analytics/dbt_utils/latest/)) is only partially tested

Please read these docs carefully and use at your own risk. [Issues](https://github.com/aurany/dbt-ibmdb2/issues/new) welcome!

Table of Contents
=================

   * [Installation](#installation)
   * [Supported features](#supported-features)
   * [Configuring your profile](#configuring-your-profile)
   * [Running Tests](#setup-dev-environment-and-run-tests)
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

*Notes:*
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
      user: my_username
      password: my_password
      extra_connect_opts: my_extra_config_options
```

| Option          | Description                                                                         | Required?                                                          | Example                                        |
| --------------- | ----------------------------------------------------------------------------------- | ------------------------------------------------------------------ | ---------------------------------------------- |
| type            | The specific adapter to use                                                         | Required                                                           | `ibmdb2`                                       |
| schema          | Specify the schema (database) to build models into                                  | Required                                                           | `analytics`                                    |
| database        | Specify the database you want to connect to                                         | Required                                                           | `testdb`                                         |
| host            | Hostname or IP-adress                                                               | Required                                                           | `localhost`                                    |
| port            | The port to use                                                                     | Optional                                                           | `50000`                                        |
| protocol        | Protocol to use                                                                     | Optional                                                           | `TCPIP`                                        |
| user            | The username to use to connect to the server                                        | Required                                                           | `my-username`                                  |
| password        | The password to use for authenticating to the server                                | Required                                                           | `my-password`                                  |
| extra_connect_opts        | Extra connection options                                | Optional                                                           | `Security=SSL;SSLClientKeyStoreDB=<path-to-client-keystore>;SSLClientKeyStash=<path-to-client-keystash>`                                  |

### Setup dev environment and run tests

Make sure you have docker and poetry installed globally.

```
make install
make test
make uninstall
```

### Reporting bugs

Want to report a bug or request a feature? Open [an issue](https://github.com/aurany/dbt-ibmdb2/issues/new).

### Credits

dbt-ibmdb2 is heavily inspired by and borrows from [dbt-mysql](https://github.com/dbeatty10/dbt-mysql) and [dbt-oracle](https://github.com/techindicium/dbt-oracle).
