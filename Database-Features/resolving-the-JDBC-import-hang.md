# Resolving the JDBC Import Hang

## Problem

* **Subject:** JDBC import operation
* **Source:** Microsoft SQL Server
* **Symptom:** The import process hangs or freezes.
* **Key Detail:** No error messages or exceptions are thrown.
* **Environment:** e.g. mssql-jdbc-13.2.0.jre11.jar, Exasol environment (Version 8.33)

When attempting to import data from Microsoft SQL Server using the JDBC driver, the following import statement hangs indefinitely. The process stalls and never completes, but no errors are logged or returned. This occurs consistently, even on a simple SELECT statement on a small table.

```sql
CREATE OR REPLACE CONNECTION my_msql_conn
    TO 'jdbc:sqlserver://dbserver;databaseName=testdb'
    USER 'my_user' IDENTIFIED BY 'my_secret';

IMPORT INTO my_table 
    FROM JDBC DRIVER='MSSQL'
    AT my_sql_conn
    STATEMENT ' SELECT * FROM orders WHERE order_state=''OK'' ';
```

## Solution

In this case, you should disable the security manager by adding NOSECURITY=YES to the settings.cfg file associated with the relevant MS SQL JDBC driver, and then upload the updated file to BucketFS.

### Example

```text
DRIVERNAME=MSSQLServer
PREFIX=jdbc:sqlserver:
FETCHSIZE=100000
INSERTSIZE=-1
NOSECURITY=YES
```

## References

* Documentation of how to [Load data from Microsoft SQL Server](https://docs.exasol.com/db/latest/loading_data/connect_sources/sql_server.htm)
* Documentation of how to [Add JDBC Driver](https://docs.exasol.com/db/latest/administration/on-premise/manage_drivers/add_jdbc_driver.htm)
* Documentation of [IMPORT](https://docs.exasol.com/db/latest/sql/import.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
