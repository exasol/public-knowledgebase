# Query to control the size of all objects in the database

## Problem Statement: Monitoring Database Data Growth

We want to keep track of how much data is stored in our database so we can prepare for future storage needs. Specifically, we need to know:

* The size of data in each table and schema.
* How the amount of data changes over time (each day, week, and month).
 
Is it possible to create a query or view that shows the size of all tables and schemas, so we can easily monitor data growth for specific time periods?

## Answer

You can utilize system tables to gather detailed information about the sizes of all objects in the database. This enables efficient monitoring and helps identify opportunities for optimization.
Below, we present an overview of various system tables available at both the metadata and history levels.

### RAW and MEM Size

In Exasol, MEM and RAW are two important metrics used to monitor and manage the size of tables and databases.

#### RAW Size

* RAW size refers to the amount of storage space that is required to store the raw, uncompressed data of a table or database.
* This is essentially the size of the data as you would see it if you exported it to a flat file or if it were stored without any optimization.
* RAW size includes all the actual data (e.g., text, numbers) present in all the rows of a table.
* It does not take into account any compression, indexing, or internal data structure optimizations that Exasol applies.
* Your Exasol license is often based on the raw data size. Exceeding this limit can prevent you from importing more data.

#### MEM Size

* Exasol is a columnar database and it automatically compresses data to optimize both disk usage and in-memory storage.
* This is the size that determines how much physical disk space is consumed by your database.
* MEM size is usually much smaller than RAW size because of the compression.
* When Exasol loads data into its in-memory cache, it's the compressed Mem size that is loaded, not the Raw size. This is a key reason for Exasol's high performance—it can fit a much larger amount of data into RAM.

### Metadata System Tables

* The metadata system tables provide information about the metadata of the database.
* The metadata system tables are placed in the system schema SYS.
* You can check the **current** size of database objects using the following tables. However, these tables only show what’s stored right now—they do not keep a record of size changes over time (no history is included).

#### EXA_ALL_OBJECT_SIZES

* This is the most comprehensive table for object sizes.
* It contains the RAW_OBJECT_SIZE (uncompressed volume) and MEM_OBJECT_SIZE (compressed volume) for all database objects (tables, schemas, views, functions, scripts) that the current user has access to.
* The sizes for schemas are calculated recursively, meaning they include the sum of sizes of all objects within that schema.
* Views, functions, and scripts are defined by text. The space this text occupies is measured as MEM-size.
* These objects don't store data themselves - they are just definitions or code - their raw_size is always 0 bytes. As a result, they do not consume any space against your schema quotas, which are typically based on raw_size.

##### Example Query EXA_ALL_OBJECT_SIZES

```SQL
SELECT
 OBJECT_NAME,
 OBJECT_TYPE,
 round(RAW_OBJECT_SIZE / (1024 * 1024),1) AS RAW_SIZE_MIB,
 round(RAW_OBJECT_SIZE / (1024 * 1024 * 1024),1) AS RAW_SIZE_GIB,
 round(MEM_OBJECT_SIZE / (1024 * 1024),1) AS MEM_SIZE_MIB,
 round(MEM_OBJECT_SIZE / (1024 * 1024 * 1024),1) AS MEM_SIZE_GIB
FROM
 EXA_ALL_OBJECT_SIZES
ORDER BY
 MEM_OBJECT_SIZE DESC;
```

#### EXA_DBA_OBJECT_SIZES

* EXA_DBA_OBJECT_SIZES is similar to EXA_ALL_OBJECT_SIZES.
* It contains the sizes of all database objects, regardless of the current user's access rights.
* You need the SELECT ANY DICTIONARY system privilege to access this table.

##### Example Query EXA_DBA_OBJECT_SIZES

```SQL
SELECT
 OBJECT_NAME,
 OBJECT_TYPE,
 round(RAW_OBJECT_SIZE / (1024 * 1024),1) AS RAW_SIZE_MIB,
 round(RAW_OBJECT_SIZE / (1024 * 1024 * 1024),1) AS RAW_SIZE_GIB,
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
 round(RAW_OBJECT_SIZE,1) AS RAW_COLUMN_SIZE_BYTES,
 round(RAW_OBJECT_SIZE / (1024 ),1) AS RAW_COLUMN_SIZE_KIB,
 round(RAW_OBJECT_SIZE / (1024 * 1024),1) AS RAW_COLUMN_SIZE_MIB,
 round(RAW_OBJECT_SIZE / (1024 * 1024 * 1024),1) AS RAW_COLUMN_SIZE_GIB,
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

##### Example Query EXA_DB_SIZE_DAILY per Day

The following query retrieves the average raw and memory object sizes (in GiB) for each day from the EXA_DB_SIZE_DAILY table within the date range from June 1, 2025 to November 1, 2025.

```SQL
SELECT 
 INTERVAL_START, 
 RAW_OBJECT_SIZE_AVG AS RAW_OBJECT_SIZE_AVG_GiB, 
 MEM_OBJECT_SIZE_AVG AS MEM_OBJECT_SIZE_AVG_GiB
FROM 
 EXA_DB_SIZE_DAILY
WHERE INTERVAL_START BETWEEN '2025-06-01 00:00:00' AND '2025-11-01 00:00:00';
```

##### Example Query EXA_DB_SIZE_DAILY per Week

The following query calculates and displays the weekly averages of raw and memory object sizes (rounded to two decimal places) in GiB from the EXA_DB_SIZE_DAILY table for the period between June 1, 2025 and November 1, 2025.

```SQL
SELECT
 TO_CHAR(INTERVAL_START, 'YYYY-IW') AS WEEK,
 ROUND(AVG(RAW_OBJECT_SIZE_AVG),2) AS RAW_OBJECT_SIZE_AVG_GiB,
 ROUND(AVG(MEM_OBJECT_SIZE_AVG),2) AS MEM_OBJECT_SIZE_AVG_GiB
FROM
 EXA_DB_SIZE_DAILY
WHERE
 INTERVAL_START BETWEEN '2025-06-01 00:00:00' AND '2025-11-01 00:00:00'
GROUP BY
 TO_CHAR(INTERVAL_START, 'YYYY-IW')
ORDER BY
 LOCAL.WEEK;
```

## References

* [Documentation of EXA_ALL_OBJECT_SIZES](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_all_object_sizes.htm)
* [Documentation of EXA_USER_OBJECT_SIZES](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_user_object_sizes.htm)
* [Documentation of EXA_DBA_OBJECT_SIZES](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_dba_object_sizes.htm)
* [Documentation of EXA_ALL_COLUMN_SIZES](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_all_column_sizes.htm)
* [Documentation of EXA_USER_COLUMN_SIZES](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_user_column_sizes.htm)
* [Documentation of EXA_DBA_COLUMN_SIZES](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_dba_column_sizes.htm)
* [Documentation of EXA_STATISTICS_OBJECT_SIZES](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_statistics_object_sizes.htm)
* [Documentation of EXA_DBA_INDICES](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_dba_indices.htm)
* [Documentation of EXA_DB_SIZE_HOURLY](https://docs.exasol.com/db/latest/sql_references/system_tables/statistical/exa_db_size_hourly.htm)
* [Documentation of EXA_DB_SIZE_DAILY](https://docs.exasol.com/db/latest/sql_references/system_tables/statistical/exa_db_size_daily.htm)
* [Documentation of EXA_DB_SIZE_MONTHLY](https://docs.exasol.com/db/latest/sql_references/system_tables/statistical/exa_db_size_monthly.htm)
* [Documentation of how the raw size is determined for different data types.](https://docs.exasol.com/db/latest/sql_references/data_types/data_type_size.htm)
* [CHANGELOG: Raw size of scripts, views, and functions set to 0 bytes](https://exasol.my.site.com/s/article/Changelog-content-11369?language=en_US)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*


