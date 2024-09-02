# How to deal with error "Adapter generated invalid pushdown query for virtual table"

## Scope

This article explains what to do in case a query using a virtual table is failing in Exasol database version 8 with error

```
Adapter generated invalid pushdown query for virtual table
```

## Diagnosis

A virtual schema used to work in version 7.1 but fails after upgrade to version 8 with an error like

```
SQL Error [04000]: Adapter generated invalid pushdown query for virtual table TBLTPS_PHONEEVENTSEX_V: Data type mismatch in column number 1 (1-indexed).
Expected DECIMAL(18,0), but got DECIMAL(19,0).
(pushdown query: IMPORT INTO (c1 DECIMAL(19, 0)) FROM JDBC AT MY_CONNECTION_NAME STATEMENT 'SELECT COUNT(*) FROM "my_schema"."my_table" LIMIT 200')
```

## Explanation

Virtual schemas are an abstraction layer that makes external data sources accessible in Exasol data analytics platform through regular SQL commands
(see also [Virtual Schemas](https://docs.exasol.com/db/latest/database_concepts/virtual_schemas.htm)).
After creating a virtual schema, you can use its tables in SQL queries and combine them with persistent tables stored in Exasol, or with any other virtual table from a different virtual schema.
The SQL optimizer translates the virtual objects into connections to the underlying systems and implicitly transfers the required data.
SQL conditions are pushed to the data sources to ensure minimum data transfer and optimum performance.

Prior version 8, Exasol to a large degree tolerated the situations where data types for columns in pushdown query did not exactly correspond to metadata stored for virtual schemas in data dictionary.

Since version 8.9.0 Exasol enforces that virtual schemas always return the correct column data types instead of trying to implicitly cast into the required type: [CHANGELOG: Correct virtual schema data types are enforced at runtime](https://exasol.my.site.com/s/article/Changelog-content-15525?language=en_US).

There are at least few real world examples that lead to an error:

1. Virtual schemas maintained by Exasol (see [Supported Dialects](https://github.com/exasol/virtual-schemas/blob/main/doc/user-guide/dialects.md))
used to generate pushdown IMPORT commands with data output types taken from the dataset returned by the third party driver.
If a third party driver's opinion about the data type of a calculation is different than the one of Exasol database, the discussed error might occur.
2. Other virtual schema adapters could have different reasons to generate pushdown queries with wrong output data types.
For example, when used as a data masking solution, a virtual schema could replace all columns called SALARY with a string `'***'` for non-privileged users, even if the SALARY column data type is DECIMAL.
This apporach could work in version 7.1, but not in version 8.

## Recommendation

1. For virtual schemas maintained by Exasol (see [Supported Dialects](https://github.com/exasol/virtual-schemas/blob/main/doc/user-guide/dialects.md)) the latest available releases have default settings covering this inconsistency.
So please download the latest virtual schema JAR, upload it to BucketFS, recreate the virtual schema adapter and refresh the virtual schema in question (or create a new one).
2. For other virtual schemas please refer to its' maintainer to fix the inconsistency.

## Additional References

* [Virtual Schemas](https://docs.exasol.com/db/latest/database_concepts/virtual_schemas.htm)
* [CHANGELOG: Correct virtual schema data types are enforced at runtime](https://exasol.my.site.com/s/article/Changelog-content-15525?language=en_US)
* [Supported Dialects](https://github.com/exasol/virtual-schemas/blob/main/doc/user-guide/dialects.md)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 
