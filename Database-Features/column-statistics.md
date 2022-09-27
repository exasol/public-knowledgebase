# Column statistics 
## Background

Exasol database automatically computes and stores column statistics on demand, e.g. when joining tables for the first time. Those statistics consist of distinct estimates, minimum & maximum values, balancing, and other information. They are used by our query optimizer for estimation of join costs, filter sensitivities, etc.

The computation of column statistics performs a complete column scan. Therefore it might be expensive, especially for large tables and/or tables not having all data in memory. This means that a query doing statistics computation may experience a significant slow down compared to the next execution.

Column statistics are maintained as part of DML statements. They are recomputed if a significant amount of data has been changed since the last computation.

## Explanation

#### Problem Description

Due to format changes, all column statistics are **invalidated** during an update from EXASOL 5.0 to EXASOL 6.0.

#### Required User Action

After the update to EXASOL 6.0, we recommend to recompute the statistics for the whole database to avoid any potential unexpected performance losses. Please note that the following command is introduced with version 6.0.4 (see ~~~~[EXASOL-2110](https://www.exasol.com/support/browse/EXASOL-2110 "Column")~~~~).

ANALYZE DATABASE REFRESH STATISTICS;

Alike other multi-table statements, ANALYZE DATABASE does an implicit COMMIT after each table minimizing transaction conflicts.

### Time Estimation

It is often useful to obtain an estimate on the duration of the ANALYZE DATABASE REFRESH STATISTICS statement.

The query below delivers such an estimate (measured in seconds) when running **before** the update (that is, on EXASOL 5.0, while statistics are still valid):


```"code
select     cast(         zeroifnull(             sum(raw_object_size) / 1024 / 1024 / 150 / nproc()         ) as dec(18, 1)     ) as COLUMN_STATISTICS_REFRESH_SECONDS from     "$EXA_COLUMN_SIZES" where     (column_schema, column_table, column_name) in (         select             column_schema,             column_table,             column_name         from             "$EXA_COLUMN_STATISTICS"         where             -- filter does not work on 6.0 before the REFRESH             min_value_estimate is not null       ); 
```
## Additional References

<https://community.exasol.com/t5/database-features/exa-statistics/ta-p/1413>

