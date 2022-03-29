# Testing dbt-ibmdb2

## Overview

Here are the steps to run the integration tests:
1. Run Docker container (optional)
1. Run tests

## Simple example

Assuming the applicable `pytest-dbt-adapter` package is installed and environment variables are set:
```bash
pytest test/dbt-adapter-tests.dbtspec
```

## Full example

### Prerequisites
- Running DB2 instance (see below for docker example)
- [`pytest-dbt-adapter`](https://pypi.org/project/pytest-dbt-adapter/) package

### Docker

[Here](https://ajstorm.medium.com/installing-db2-on-your-coffee-break-5be1d811b052) is one guide on "How to Run DB2 in a Docker Container on macOS".

In the docker commands below, the default DB2 username is `db2inst1`, password `ibm123`, database `testdb`, port `50000` and the default server name is `localhost`.

#### DB2 LUW
`docker run -itd --name db2 --restart unless-stopped -e DBNAME=testdb -v ~/:/database -e DB2INST1_PASSWORD=ibm123 -e LICENSE=accept -p 50000:50000 --privileged=true ibmcom/db2`

### Run tests

Run the test specs in this repository:
```
pytest -v test/dbt-adapter-tests.dbtspec
```
