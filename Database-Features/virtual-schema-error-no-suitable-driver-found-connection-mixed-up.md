# Virtual Schema Error No suitable driver found (connection mixed up)

## Problem

I have these two connections defined:

### Connection EXA_CONN

```sql
ALTER CONNECTION EXA_CONN 
TO '192.168.6.11:8563' 
USER 'user1' 
IDENTIFIED BY 'pw';
```

### Connection EXA_CONN_JDBC

```sql
ALTER CONNECTION EXA_CONN_JDBC
 TO 'jdbc:exa:192.168.6.11:8563' 
USER 'user1' 
IDENTIFIED BY 'pw';
```

I tested both connections using the following statements:

```sql
SELECT * FROM ( IMPORT INTO (i INT) FROM EXA AT EXA_CONNECTION  TABLE TEST.T1);

SELECT * FROM ( IMPORT INTO (i INT) FROM JDBC AT JDBC_CONNECTION  TABLE TEST.T1);
```

Both connections were successful.

### CREATE VIRTUAL SCHEMA SQL

and I try to execute this statement

```sql
CREATE VIRTUAL SCHEMA VIRTUAL_SCHEMA_TEST
USING ADAPTER.JDBC_ADAPTER_SCRIPT
WITH
CONNECTION_NAME = 'EXA_CONN'
EXA_CONNECTION = 'EXA_CONN_JDBC'
IMPORT_FROM_EXA = 'true'
SCHEMA_NAME = 'SCHEMA_FOR_VS_SOURCE';
```

### Error

I get the following error

```text
[Code: 0, SQL State: 22002] VM error: F-UDF-CL-LIB-1126: F-UDF-CL-SL-JAVA-1006: F-UDF-CL-SL-JAVA-1026:
com.exasol.ExaUDFException: F-UDF-CL-SL-JAVA-1068: Exception during singleCall adapterCall
com.exasol.adapter.jdbc.RemoteMetadataReaderException: E-VSEXA-4: Unable to create Exasol remote metadata reader.
...
Caused by: java.sql.SQLException: No suitable driver found for 192.168.6.11:8563
...
com.exasol.adapter.dialects.exasol.ExasolSqlDialect.createRemoteMetadataReader(ExasolSqlDialect.java:70)
... 9 more
(Session: 1821396514322382848)
```

## Explanation

The "No suitable driver" exception is thrown by the DriverManager when none of the registered driver implementations can recognize or handle the specified URL.

### EXA_CONNECTION (Import from Exa)

By setting the IMPORT_FROM_EXA property, you have instructed the adapter to use the faster, parallel IMPORT FROM EXA command to load data from another Exasol instance, instead of using IMPORT FROM JDBC.
The EXA_CONNECTION property should specify the name of the connection definition used internally by the IMPORT FROM EXA command.

### CONNECTION_NAME (JDBC connection)

The CONNECTION_NAME property is used to define the named JDBC connection for reading metadata.

## Solution

In your case, EXA_CONNECTION should be set to EXA_CONN, not to the JDBC connection EXA_CONN_JDBC. Therefore, you need to update the connection parameters as follows.

```sql
CREATE VIRTUAL SCHEMA VIRTUAL_SCHEMA_TEST
USING ADAPTER.JDBC_ADAPTER_SCRIPT
WITH
CONNECTION_NAME = 'EXA_CONN_JDBC'
EXA_CONNECTION = 'EXA_CONN'
IMPORT_FROM_EXA = 'true'
SCHEMA_NAME = 'SCHEMA_FOR_VS_SOURCE';
```

## References

* Documentation of [CREATE CONNECTION](https://docs.exasol.com/db/latest/sql/create_connection.htm)
* Documentation of [IMPORT](https://docs.exasol.com/db/latest/sql/import.htm)
* Documentation of [Virtual Schema's Exasol SQL Dialect](https://github.com/exasol/exasol-virtual-schema/blob/main/doc/dialects/exasol.md)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
