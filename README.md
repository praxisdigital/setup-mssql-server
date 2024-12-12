# setup-mssql-server
This action sets up a SQL Server instance on a Ubuntu runner and create an extra database and user.

## Inputs
* ``sa-password`` The password of the sa user. Default is **Password@12345!**.
* ``version`` The version of SQL Server to be used. Default is **2022**.
* ``user`` The username of the user to be created. Default is **test**.
* ``password`` The password of the user to be created. Default is **test**.
* ``database`` The name of the database to be created. Default is **test**.
* ``port`` The port to be used by the SQL Server container that expose to the host. Default is **1433**.
* ``container-name`` The name of the container to be created. Default is **sql-server-container**.
* ``image-tag`` The tag of the SQL Server image to be used. If specified it will override ``version`` input. Default is empty.

## Usage

Basic usage.
```yaml
- name: Set up SQL Server
  uses: enchman/setup-mssql-server@v1
```


Fully specify the version of SQL Server you want to use, the sa password, the user, password, database, port and container name.

```yaml
- name: Set up SQL Server
  uses: enchman/setup-mssql-server@v1
  with:
    version: 2022
    sa-password: Password@12345
    user: test
    password: test
    database: test
    port: 1433
    container-name: sql-server-container
```