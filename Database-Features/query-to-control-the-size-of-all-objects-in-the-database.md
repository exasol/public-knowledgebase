# Query to control the size of all objects in the database

## Question

Is it possible to have a query or a view to control the size of all objects in the database?

## Answer

You can utilize system tables to gather detailed information about the sizes of all objects in the database. This enables efficient monitoring and helps identify opportunities for optimization.
Below, we present an overview of various system tables available at both the metadata and history levels.

### Metadata System Tables

* The metadata system tables provide information about the metadata of the database.
* The metadata system tables are placed in the system schema SYS.
* The **current** size of the objects can be monitored in the following tables.

#### EXA_ALL_OBJECT_SIZES

* This is the most comprehensive table for object sizes.
* It contains the RAW_OBJECT_SIZE (uncompressed volume) and MEM_OBJECT_SIZE (compressed volume) for all database objects (tables, schemas, views, functions, scripts) that the current user has access to.
* The sizes for schemas are calculated recursively, meaning they include the sum of sizes of all objects within that schema.
* For views, functions, and scripts, the size represents the text size of their definitions.

##### Example Query EXA_ALL_OBJECT_SIZES

```SQL
SELECT
    OBJECT_NAME,
    OBJECT_TYPE,
    round(MEM_OBJECT_SIZE / (1024 * 1024),1) AS MEM_SIZE_MIB,
    round(MEM_OBJECT_SIZE / (1024 * 1024 * 1024),1) AS MEM_SIZE_GIB
FROM
    EXA_ALL_OBJECT_SIZES
ORDER BY
    MEM_OBJECT_SIZE DESC;
```

#### EXA_DBA_OBJECT_SIZES

* EXA_DBA_OBJECT_SIZES  is similar to EXA_ALL_OBJECT_SIZES.
* It contains the sizes of all database objects, regardless of the current user's access rights.
* You need the SELECT ANY DICTIONARY system privilege to access this table.

##### Example Query EXA_DBA_OBJECT_SIZES

```SQL
SELECT
    OBJECT_NAME,
    OBJECT_TYPE,
    round(MEM_OBJECT_SIZE / (1024 * 1024),1) AS MEM_SIZE_MIB,
    round(MEM_OBJECT_SIZE / (1024 * 1024 * 1024),1) AS MEM_SIZE_GIB
FROM
    EXA_DBA_OBJECT_SIZES
ORDER BY
    MEM_OBJECT_SIZE DESC;
```

#### EXA_DBA_COLUMN_SIZES

* This table provides more granular information, listing the raw and compressed sizes for individual columns within all user tables.
* This is very useful for identifying which columns contribute most to table size.

##### Example Query EXA_DBA_COLUMN_SIZES

```SQL
SELECT
    COLUMN_SCHEMA,
    COLUMN_TABLE,
    COLUMN_NAME,
    round(MEM_OBJECT_SIZE,1) AS MEM_COLUMN_SIZE_BYTES,
    round(MEM_OBJECT_SIZE / (1024 ),1) AS MEM_COLUMN_SIZE_KIB,
    round(MEM_OBJECT_SIZE / (1024 * 1024),1) AS MEM_COLUMN_SIZE_MIB,
    round(MEM_OBJECT_SIZE / (1024 * 1024 * 1024),1) AS MEM_COLUMN_SIZE_GIB
FROM
    EXA_DBA_COLUMN_SIZES
ORDER BY
    MEM_OBJECT_SIZE DESC nulls last;
```

#### EXA_STATISTICS_OBJECT_SIZES

* This table contains the sizes of statistical system tables themselves, aggregated by type (e.g., AUDIT, DB_SIZE, MONITOR).

##### Example Query EXA_STATISTICS_OBJECT_SIZES

```SQL
SELECT * FROM EXA_STATISTICS_OBJECT_SIZES;
```

#### EXA_DBA_INDICES

* EXA_DBA_INDICES is directly relevant to table size because it provides information about the storage consumed by the indexes associated with a table.
* Specifically, the key column for understanding index size is MEM_OBJECT_SIZE which indicates the size of the index in bytes (at the last COMMIT).
* This is the real, compressed size of the index as stored in memory.
* Larger indexes contribute to higher memory consumption by your Exasol database.

##### Example Query EXA_DBA_INDICES

```SQL
SELECT INDEX_SCHEMA, INDEX_TABLE, INDEX_OBJECT_ID, MEM_OBJECT_SIZE
FROM EXA_DBA_INDICES;
```

### Statistical System Tables

* This section describes the **statistical** system tables in Exasol.
* The statistical system tables are placed in the system schema EXA_STATISTICS.
* The statistical system tables contain historical data about the usage and the status of the DBMS.  
* This data can be used to analyze trends, identify patterns, and make predictions about future events or conditions.

#### EXA_DB_*

* EXA_DB_SIZE_HOURLY, EXA_DB_SIZE_DAILY, EXA_DB_SIZE_MONTHLY system tables provide aggregated information about database sizes at a cluster level, including average and maximum uncompressed, compressed, auxiliary (indexes), and statistics sizes over different intervals.
* These are great for trending and capacity planning.

##### Example Query EXA_DB_SIZE_HOURLY

```SQL
SELECT INTERVAL_START, MEM_OBJECT_SIZE_AVG as MEM_OBJECT_SIZE_AVG_GiB
FROM EXA_DB_SIZE_HOURLY;
```

## References

* Documentation of [EXA_ALL_OBJECT_SIZES](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_all_object_sizes.htm)
* Documentation of [EXA_USER_OBJECT_SIZES](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_user_object_sizes.htm)
* Documentation of [EXA_DBA_OBJECT_SIZES](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_dba_object_sizes.htm)
* Documentation of [EXA_ALL_COLUMN_SIZES](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_all_column_sizes.htm)
* Documentation of [EXA_USER_COLUMN_SIZES](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_user_column_sizes.htm)
* Documentation of [EXA_DBA_COLUMN_SIZES](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_dba_column_sizes.htm)
* Documentation of [EXA_STATISTICS_OBJECT_SIZES](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_statistics_object_sizes.htm)
* Documentation of [EXA_DBA_INDICES](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_dba_indices.htm)
* Documentation of [EXA_DB_SIZE_HOURLY](https://docs.exasol.com/db/latest/sql_references/system_tables/statistical/exa_db_size_hourly.htm)
* Documentation of [EXA_DB_SIZE_DAILY](https://docs.exasol.com/db/latest/sql_references/system_tables/statistical/exa_db_size_daily.htm)
* Documentation of [EXA_DB_SIZE_MONTHLY](https://docs.exasol.com/db/latest/sql_references/system_tables/statistical/exa_db_size_monthly.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
