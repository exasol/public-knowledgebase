# Syntax error found in connection string in a Exa-Connection with a JDBC connection String

## Problem

I have the following connection string:

```sql
CREATE CONNECTION exa_connection
    TO 'jdbc:exa:192.168.6.6..7:8563'
    USER 'my_user'
    IDENTIFIED BY 'my_secret';
```

When I execute the following IMPORT-statement

```SQL
IMPORT INTO Test.impT FROM EXA AT exa_connection TABLE Test.sourceT;
```

I get this error message:

> [!CAUTION]
> [Code: 0, SQL State: 42636]  ETL-4211: Connection from n12 to external EXASolution at jdbc:exa:192.168.6.6..7 failed. [Syntax error found in connection string.] (Session: 1836541654066528257)

## Explanation

You can choose the the database source among an Exasol connection (EXA), a native connection to an Oracle database (ORA), or a JDBC connection to any database (JDBC).

In the example above the database source is EXA and not JDBC. The "EXA" connection type refers to Exasol's native, high-performance protocol specifically designed for data transfer between two Exasol databases whereas jdbc:exa: is the prefix that you use in Java applications to indicate a connection to an Exasol database using JDBC.

In the example above a JDBC connection string is passed to a native EXA connection. Thus the (Exa)-driver recognize invalid syntax $\textsf{\color{red}{jdbc:exa:}}$ in the connection string. 

## Solution

We have to remove $\textsf{\color{red}{jdbc:exa:}}$ from the connection string:

```sql 
CREATE CONNECTION exa_connection 
    TO '192.168.6.11..12:8563'
    USER 'my_user' 
    IDENTIFIED BY 'my_secret';
```

## References

* [CHANGELOG: Fixed incorrect error messages for invalid connection string syntax in Exasol ODBC driver](https://exasol.my.site.com/s/article/Changelog-content-15363?language=en_US&name=Changelog-content-15363)
* [CREATE CONNECTION](https://docs.exasol.com/db/latest/sql/create_connection.htm)
* [IMPORT](https://docs.exasol.com/db/latest/sql/import.htm)

## Author

* [Peggy Schmidt-Mittenzwei](https://github.com/PeggySchmidtMittenzwei)


*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
