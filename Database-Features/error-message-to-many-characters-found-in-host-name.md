# Error Message To many '/' characters found in host name

## Problem

I have the following connection defined:

```SQL
CREATE OR REPLACE CONNECTION my_msql_conn
    TO 'jdbc:sqlserver://192.168.6.2;databaseName=testdb'
    USER 'my_user' IDENTIFIED BY 'my_secret';
```

When  I execute the following statement

```SQL
IMPORT INTO my_table 
    FROM EXA 
    AT my_msql_conn
    STATEMENT ' SELECT * FROM orders WHERE order_state=''OK'' ';
```

I get the following error message

```text
[Code: 0, SQL State: 42636]  ETL-4211: Connection from n11 to external EXASolution at jdbc:sqlserver://192.168.6.2 failed.
[To many '/' characters found in host name, unable to parse.] (Session: 1842165955643375616)
```

## Answer

The Exa connection does not use the sqlserver protocol. It uses exasol. When the Exasol driver tries to parse jdbc:sqlserver://, it gets confused by the structure, specifically the multiple forward slashes (//) after a protocol it doesn't recognize.

In the Exasol context, this is a typo, because what is intended is a JDBC connection instead of an EXA connection.

### Mitigation

Replace the keyword EXA with JDBC

```SQL
IMPORT INTO my_table 
    FROM JDBC 
    AT my_msql_conn
    STATEMENT ' SELECT * FROM orders WHERE order_state=''OK'' ';
```

## References

* Documentation of [CREATE CONNECTION](https://docs.exasol.com/db/latest/sql/create_connection.htm)
* Documentation of [IMPORT](https://docs.exasol.com/db/latest/sql/import.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
