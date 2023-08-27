# How to estimate duration of REORGANIZE DATABASE when enlarging a cluster 
## Background

When you add new nodes to your database cluster (enlargement), those new nodes will not yet have any data. Furthermore, all distribution keys and indices have been invalidated on the first startup of the enlarged database. Therefore the table data needs redistribution, and all the indices must be rebuilt.

## Prerequisites

The general recommendation to accomplish this is the `REORGANIZE DATABASE` command. It redistributes tables and rebuilds all indices. Each processed table is committed immediately so transaction dependencies are minimized. You can find more information about the `REORGANIZE` command here: [reorganize](https://docs.exasol.com/sql/reorganize.htm).

## How to estimate the duration of REORGANIZE DATABASE when enlarging a cluster

## Step 1

To estimate the duration of the `REORGANIZE DATABASE` you can use the SQL statement from the "Step 1" section in the attached "REORGANIZE estimator" .sql file. There are two files attached - one for versions prior to 6.1 and another one for versions starting from 6.1.

## Step 2

The first column is the overall duration of the REORGANIZE DATABASE in seconds. Then follow delete reorganization time, table redistribution time, and index rebuild time, all in seconds. The last column represents some general overhead as each table in the database has to be checked and committed.



| OVERALL_SECONDS | DELETE_SECONDS | DISTRIBUTE_SECONDS | INDEX_REBUILD_SECONDS | TABLE_SECONDS |
| --- | --- | --- | --- | --- |
| 9515 | 11 | 3034 | 1000 | 5470 |

Please note, that the actual duration may differ from the computed one, because of concurrency behavior or hardware specifics.

If you have high-performance hardware (several hundred MB/s of HDD_READ_MAX and NET_MAX in EXA_MONITOR_DAILY), you may reduce the reorganize time by running three independent reorganize streams in parallel. This improves resource utilization of your database (mostly HDD_READ and NET) and speeds up the overall process. You may find more information about the EXA_MONITOR_DAILY table here: [exa_monitor_daily](https://docs.exasol.com/sql_references/system_tables/statistical/exa_monitor_daily.htm).

## Step 3

You can use the SQL query from the "Step 3" section in the attached "REORGANIZE estimator" .sql file to generate those three REORGANIZE streams. There are two files attached - one for versions prior to 6.1 and another one for versions starting from 6.1.

Please ensure to run the above statements right before enlarging the cluster as rebuild times of invalidated indices cannot be estimated thereafter.

## Additional Notes

The generated SQL statements for single-table REORGANIZEs should be split into three streams "small tables", "big tables" and "indices" which will have all comparable overall stream durations. The REORGANIZE TABLE comments could help you to check overall progress (stream time estimate) and estimate the overall finishing time using EXA_DBA_SESSIONS or EXA_DBA_PROFILE_RUNNING.


```sql
...
REORGANIZE TABLE "TPCDS"."WEB_RETURNS";                                                        -- stream "big tables": table estimate 40 sec, stream time estimate 2679 sec                 
REORGANIZE TABLE "TPC"."CUSTOMER";                                                             -- stream "big tables": table estimate 90 sec, stream time estimate 2769 sec                 
...
REORGANIZE TABLE "TPCDS"."CATALOG_SALES";                                                      -- stream "indices": table estimate 105 sec, stream time estimate 1367 sec                  
REORGANIZE TABLE "TPCDS"."STORE_SALES";                                                        -- stream "indices": table estimate 134 sec, stream time estimate 1502 sec                  
REORGANIZE TABLE "TPC"."LINEITEM";                                                             -- stream "indices": table estimate 239 sec, stream time estimate 1741 sec                  
...
REORGANIZE TABLE "TPCDS"."HOUSEHOLD_DEMOGRAPHICS";                                             -- stream "small tables": table estimate 1 sec, stream time estimate 1554 sec               
REORGANIZE TABLE "TPCDS"."CATALOG_PAGE";                                                       -- stream "small tables": table estimate 1 sec, stream time estimate 1555 sec               
...

```
We do not recommend using more than three streams as index rebuild performance will deteriorate strongly if DBRAM gets heavily under stress by parallel big index rebuilds or big table redistributions.

As long as the REORGANIZE is not finished, we recommend avoiding running queries that access large tables and, therefore, may try to create big indices. As the creation of big indices needs a lot of memory, several index creations in parallel can easily interfere with each other (swapping). This restriction does not apply to DML statements as they normally don't create indices. Index maintenance is a part of DML, but won't be executed on invalidated indices.

## Downloads
* [REORGANIZE_estimator_6.0_and_before.sql](https://github.com/exasol/public-knowledgebase/blob/main/Database-Features/attachments/REORGANIZE_estimator_6.0_and_before.sql)
* [REORGANIZE_estimator_for_6.1_and_after.sql](https://github.com/exasol/public-knowledgebase/blob/main/Database-Features/attachments/REORGANIZE_estimator_for_6.1_and_after.sql)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 