# Recompress data after upgrading to Exasol 2025.1.3 or later

## Background

Exasol 2025.1.3 and 2025.2.0 introduced new block compressors that store data more compactly. They are included in all later releases, such as 2026.1. They only apply to data written after the upgrade. Existing data keeps its old, larger footprint until it is rewritten.

Exasol chooses a compressor per column and data block, based on the data it finds. Two changes improve compression:

| Change | What it improves |
| --- | --- |
| [Two new block compressors for columns with NULL values](https://docs.exasol.com/db/latest/changelogs/26664.htm) | Sparse and nullable columns, which were not always compressed optimally before |
| [Special compression now covers up to 64,000 distinct values (was 32,000)](https://docs.exasol.com/db/latest/changelogs/26225.htm) | Fixed-size columns with medium cardinality, such as codes, categories and status values |

Both are enabled by default, and there is nothing to configure.

### Why existing data does not benefit automatically

The changelogs for both changes state: "Only new or recompressed data blocks are affected."

An upgrade does not rewrite your tables. This is intentional, to keep the maintenance window for the update itself short. Data loaded after the upgrade uses the new compressors, but historical data stays as it was. Large fact tables and archives that are rarely modified are where the savings are biggest, and they never pick up the new compressors on their own.

Two SQL statements fix that:

* [`RECOMPRESS ... ENFORCE`](https://docs.exasol.com/db/latest/sql/recompress.htm) re-encodes every column with the best compressor now available. Without `ENFORCE`, Exasol only recompresses columns where it expects a significant improvement.
* A final [`REORGANIZE DATABASE`](https://docs.exasol.com/db/latest/sql/reorganize.htm) removes rows that are only marked as deleted and recreates internal indexes in the tables that need it, and also covers internal system data.

### What you gain

Recompression shrinks the compressed size of your data (`MEM_OBJECT_SIZE`). The uncompressed size (`RAW_OBJECT_SIZE`) stays the same and therefore does not have an impact on your raw data size license. In field deployments, the compressed size dropped by roughly 20% to 40%, depending on the data.

* **More data in memory.** Exasol processes compressed data in RAM, so the same DB RAM holds a larger share of your working set and fewer reads go to disk.
* **Faster queries on large tables.** There is less data to scan and less I/O per query.
* **Less disk space.** Storage usage drops, which postpones the next storage expansion.
* **Smaller, faster backups.** Backups copy the compressed data blocks, so full and incremental backups shrink and finish faster. The gain is somewhat smaller than the compression gain, because backups receive additional compression on their way to the archive volume.
* **Lower recommended DB RAM.** The recommended DB RAM is derived from the compressed size, which helps with sizing and capacity planning.
* **Cleaner tables.** In tables with many rows that are only marked as deleted, the final `REORGANIZE DATABASE` removes them.

### Why do it soon after the upgrade

1. **The data does not fix itself.** Historical data keeps the old compression for as long as it is not rewritten.
2. **The timing is right.** You have just planned a maintenance window and tested the new release, and a fresh full backup fits naturally into that plan.
3. **Coming from version 7?** Data migrated from version 7 to version 8 can end up less well compressed than before, and recompression is the first remedy.
4. **Capacity pressure only grows.** Every month on the old footprint brings you closer to a storage expansion or a RAM upgrade that you might not need.

## Prerequisites

The operation does not require a database downtime, but it rewrites most of your data. Plan these points before you start:

| Topic | What to do |
| --- | --- |
| Version | Exasol 2025.1.3 or later, including all 2025.2 and 2026.1 releases. Use the latest patch of your release line. |
| Test first | Run the procedure on a test or development database to measure the duration and the gain on your own data. |
| Free disk space | New blocks are written before the old ones are released, so the operation temporarily needs extra space. Make sure free storage comfortably exceeds the compressed size of your largest table plus its indexes, multiplied by the number of parallel sessions. If it does not, expand storage first. Working table by table, smallest first, keeps the peak low. |
| Backups | Take a backup before you start, and run a full backup (level 0) after the operation. Do not run a backup while the operation is running. |
| Locks | `RECOMPRESS` and `REORGANIZE` put a write lock on each table while they process it. Concurrent ETL or DML on that table is blocked until the table is committed, or fails with a transaction conflict. Schedule the operation outside your load windows. |
| Timing | Expect anything from minutes to many hours, depending on data volume and I/O. The operation runs alongside normal workload with a moderate performance impact, but large queries during `REORGANIZE` can slow it down. A night or weekend window is ideal. |
| Privileges | `USE ANY SCHEMA` (or `USAGE` on the schema) plus a modifying `ANY TABLE` system privilege, a modifying object privilege, or ownership of the affected tables. Reading `EXA_DBA_OBJECT_SIZES`, `EXA_DBA_INDICES` and `EXA_DBA_SESSIONS` requires `SELECT ANY DICTIONARY`. |
| Session | Use sessions that do not time out, such as EXAplus inside `screen` or `tmux`, or a scheduled job. Keep autocommit enabled (the default), because `RECOMPRESS TABLE` does not commit by itself. |

## How to recompress your data after the upgrade

All statements in this section run in the database (SQL). `EXA_DBA_OBJECT_SIZES` and `EXA_DBA_INDICES` report bytes, and `EXA_DB_SIZE_LAST_DAY` reports GiB.

### Step 1: Record a baseline

Run the following queries and keep the output so you can compare the results afterwards.

```sql
-- Database totals (latest measurement, peak recommended DB RAM of the last 24 hours)
SELECT MEASURE_TIME,
       RAW_OBJECT_SIZE                             AS RAW_GIB,
       MEM_OBJECT_SIZE                             AS MEM_GIB,
       ROUND(RAW_OBJECT_SIZE / MEM_OBJECT_SIZE, 2) AS COMPRESSION_RATIO,
       (SELECT MAX(RECOMMENDED_DB_RAM_SIZE)
          FROM EXA_STATISTICS.EXA_DB_SIZE_LAST_DAY) AS MAX_RECOMMENDED_DB_RAM_GIB,
       STORAGE_SIZE                                AS STORAGE_GIB,
       USE                                         AS STORAGE_USE_PCT
  FROM EXA_STATISTICS.EXA_DB_SIZE_LAST_DAY
 ORDER BY MEASURE_TIME DESC
 LIMIT 1;

-- Per schema, largest first
SELECT OBJECT_NAME                                    AS SCHEMA_NAME,
       ROUND(RAW_OBJECT_SIZE / 1024 / 1024 / 1024, 2) AS RAW_GIB,
       ROUND(MEM_OBJECT_SIZE / 1024 / 1024 / 1024, 2) AS MEM_GIB,
       ROUND(RAW_OBJECT_SIZE / MEM_OBJECT_SIZE, 2)    AS COMPRESSION_RATIO
  FROM SYS.EXA_DBA_OBJECT_SIZES
 WHERE OBJECT_TYPE = 'SCHEMA'
   AND NOT OBJECT_IS_VIRTUAL
   AND MEM_OBJECT_SIZE > 0
 ORDER BY MEM_OBJECT_SIZE DESC;
```

The first query returns one row with the database totals. The recommended DB RAM depends on the workload, so the query reports its peak over the last 24 hours rather than the latest value, which is often taken at a quiet time. The second query returns one row per schema, largest first.

### Step 2: Check free space

```sql
-- Check free space against the largest table, including its indexes
SELECT d.STORAGE_SIZE                                    AS STORAGE_GIB,
       ROUND(d.STORAGE_SIZE * (100 - d.USE) / 100, 1)    AS FREE_GIB,
       t.ROOT_NAME || '.' || t.OBJECT_NAME               AS LARGEST_TABLE,
       ROUND(t.TABLE_BYTES / 1024 / 1024 / 1024, 1)      AS LARGEST_TABLE_MEM_GIB
  FROM (SELECT * FROM EXA_STATISTICS.EXA_DB_SIZE_LAST_DAY
         ORDER BY MEASURE_TIME DESC LIMIT 1) d
 CROSS JOIN (SELECT o.ROOT_NAME, o.OBJECT_NAME,
                    o.MEM_OBJECT_SIZE + COALESCE(SUM(i.MEM_OBJECT_SIZE), 0) AS TABLE_BYTES
               FROM SYS.EXA_DBA_OBJECT_SIZES o
               LEFT JOIN SYS.EXA_DBA_INDICES i
                 ON i.INDEX_SCHEMA = o.ROOT_NAME
                AND i.INDEX_TABLE  = o.OBJECT_NAME
              WHERE o.OBJECT_TYPE = 'TABLE'
                AND NOT o.OBJECT_IS_VIRTUAL
              GROUP BY o.ROOT_NAME, o.OBJECT_NAME, o.MEM_OBJECT_SIZE
              ORDER BY TABLE_BYTES DESC
              LIMIT 1) t;
```

The query returns one row with the total storage, the free storage, and the name and compressed size of your largest table including its indexes, all in GiB.

Continue when `FREE_GIB` comfortably exceeds `LARGEST_TABLE_MEM_GIB` multiplied by the number of parallel sessions you plan to use (see Step 4). On Exasol SaaS, contact Exasol Support before you start.

### Step 3: Make sure you have a recent backup

You should already have taken a backup before the database update. If data has changed since then, take an incremental backup now. For on-premises installations, see [Backup and restore](https://docs.exasol.com/db/latest/administration/on-premise/backup_restore.htm). On Exasol SaaS, contact Exasol Support.

Make sure no backup is running when you start, and that none is scheduled during the operation. A running backup keeps the old data blocks in use, so they cannot be released while the new ones are being written.

### Step 4: Generate and run the script, smallest table first

**Warning:** The statements temporarily need extra disk space, because new blocks are written before the old ones are released. If storage fills up, the database can crash or restart unexpectedly (see [changelog 11015](https://docs.exasol.com/db/latest/changelogs/11015.htm)). Make sure you completed Step 2, and keep an eye on storage usage while the script runs.

`RECOMPRESS SCHEMA` already works table by table and commits after each table, but it processes the tables one after the other in a single session, in an order you do not control. Generating one statement per table lets you start with the smallest tables, split the work into parallel sessions, and pause or resume at any point.

`RECOMPRESS` does not fully use the available CPU and disk throughput when it runs in a single session, so running it in several parallel sessions usually shortens the total time considerably. Two or three sessions are a good starting point. More sessions put more load on DB RAM and raise the disk space peak.

The following query generates one statement per row and assigns each table to one of three sessions (`SESSION_NO` 0, 1 and 2). Change the `3` to the number of sessions you want:

```sql
-- Generate commands: 1 statement per row, tables spread over 3 sessions
SELECT t.SESSION_NO,
       'RECOMPRESS TABLE "' || t.ROOT_NAME || '"."' || t.OBJECT_NAME || '" ENFORCE;' AS STMT
  FROM (SELECT MOD(ROW_NUMBER() OVER (ORDER BY MEM_OBJECT_SIZE, ROOT_NAME, OBJECT_NAME) - 1, 3) AS SESSION_NO,
               MEM_OBJECT_SIZE, ROOT_NAME, OBJECT_NAME
          FROM SYS.EXA_DBA_OBJECT_SIZES
         WHERE OBJECT_TYPE = 'TABLE'
           AND NOT OBJECT_IS_VIRTUAL) t
 ORDER BY t.SESSION_NO, t.MEM_OBJECT_SIZE, t.ROOT_NAME, t.OBJECT_NAME;
```

The query returns one statement per table, smallest table first. To process a single schema only, add `AND ROOT_NAME = 'MY_SCHEMA'` to the inner `WHERE` clause.

Save the statements of each `SESSION_NO` to a separate script file, and run each file in its own session at the same time. Each line is a single statement, so any SQL client runs the files as they are:

```sql
RECOMPRESS TABLE "SALES"."REGIONS" ENFORCE;
RECOMPRESS TABLE "SALES"."ORDERS" ENFORCE;
```

When all sessions have finished, check for tables with a high share of rows marked as deleted. `REORGANIZE DATABASE` processes them one after the other in a single session, which can take a long time if there are many of them, or large ones. The following query generates a `REORGANIZE TABLE` statement for each of these tables, spread over three sessions in the same way:

```sql
-- Generate commands: REORGANIZE for tables with many deleted rows, 3 sessions
SELECT t.SESSION_NO,
       'REORGANIZE TABLE "' || t.TABLE_SCHEMA || '"."' || t.TABLE_NAME || '";' AS STMT
  FROM (SELECT MOD(ROW_NUMBER() OVER (ORDER BY TABLE_ROW_COUNT, TABLE_SCHEMA, TABLE_NAME) - 1, 3) AS SESSION_NO,
               TABLE_ROW_COUNT, TABLE_SCHEMA, TABLE_NAME
          FROM SYS.EXA_DBA_TABLES
         WHERE DELETE_PERCENTAGE >= 12.5
           AND NOT TABLE_IS_VIRTUAL) t
 ORDER BY t.SESSION_NO, t.TABLE_ROW_COUNT, t.TABLE_SCHEMA, t.TABLE_NAME;
```

If the query returns rows, run them as before, one script file per `SESSION_NO` in parallel sessions. If it returns no rows, skip this part.

Finally, run one statement in a single session:

```sql
REORGANIZE DATABASE;
```

Without `ENFORCE`, it only processes the tables that still need it, so after the previous part there is little left to do. It also covers internal system data, such as auditing and profiling data, that you cannot address with table-level statements.

**Schema quotas:** If a schema has a raw size limit (`RAW_SIZE_LIMIT`), `REORGANIZE` can fail on a table in that schema while it rewrites the data, and abort. Before you start, remove the limits with `ALTER SCHEMA ... SET RAW_SIZE_LIMIT = NULL` and set them again when the operation is complete.

### Step 5: Monitor progress

Check the running statements, and keep an eye on storage usage:

```sql
-- Monitor progress
SELECT SESSION_ID, USER_NAME, STATUS, DURATION, ACTIVITY, SQL_TEXT
  FROM SYS.EXA_DBA_SESSIONS
 WHERE UPPER(SQL_TEXT) LIKE 'RECOMPRESS%'
    OR UPPER(SQL_TEXT) LIKE 'REORGANIZE%'
    OR UPPER(SQL_TEXT) LIKE 'COMMIT%';
```

The query returns one row for each session that is running `RECOMPRESS`, `REORGANIZE` or the commit that follows each table. The commit of a large table can take from seconds to minutes. `ACTIVITY` shows the current operation, and `DURATION` shows how long the statement has been running. Use the output of your script sessions to confirm when they have finished.

### Step 6: Run a full backup

As soon as the last statement has committed, run a full backup (level 0) and confirm that it completes successfully. This step is not mandatory, but it is highly recommended. Almost every data block is new after the operation, so an incremental backup would be nearly as large as a full one, and a full backup gives you a clean restore baseline on the new layout.

### Step 7: Compare the results

A few hours later -- after a representative workload has been running -- run the Step 1 queries again. Compare the compressed size, compression ratio, and recommended DB RAM with your baseline. Compare the size and duration of the new full backup with the previous one.

## Additional Notes

**I already use 2025.1.3 or later and am upgrading to 2026.1. Do I need to run this again?** Not because of the upgrade. The new compressors have been available since 2025.1.3, so upgrading to 2026.1 does not add new ones. If you have not recompressed your data since you upgraded to 2025.1.3 or later, run the procedure now. Otherwise, you do not need to run it again.

**Why use `ENFORCE` with `RECOMPRESS`?** Without it, `RECOMPRESS` skips columns where it does not expect a significant improvement, so much of your older data keeps the old compressors. The final `REORGANIZE DATABASE` deliberately runs without `ENFORCE`: it skips tables that do not need a reorganization, for example tables with less than 12.5% of their rows marked as deleted (see `DELETE_PERCENTAGE` in `EXA_ALL_TABLES`).

**Why not also run `REORGANIZE ... ENFORCE` on every table?** `RECOMPRESS ... ENFORCE` already rewrites every column with the new compressors. `REORGANIZE` may recompress columns as well, but only where it decides it is worthwhile, so it does not replace `RECOMPRESS`. Its other actions, removing rows that are only marked as deleted and recreating indexes, are only needed on some tables. The targeted `REORGANIZE TABLE` statements (without `ENFORCE`) cover tables with many deleted rows in parallel sessions, and the final `REORGANIZE DATABASE` covers whatever is left. Indexes are also maintained automatically during normal operation. Running `REORGANIZE ... ENFORCE` on every table would roughly double the run time and disk activity.

**Table by table, or `RECOMPRESS DATABASE`?** Both commit after each table, so neither runs as one large transaction. The table-level script lets you choose the order, run several sessions in parallel, and pause between tables. `RECOMPRESS DATABASE ENFORCE` works too, but runs as one long, sequential operation in a single session.

**Is it safe to run while users are working?** Yes, but plan for it. With autocommit enabled, each `RECOMPRESS TABLE` and `REORGANIZE TABLE` statement is committed on its own, and `REORGANIZE DATABASE` commits after each table, so a failure or cancellation leaves the tables processed so far completed, and the rest unchanged. Unlike `RECOMPRESS SCHEMA` and `RECOMPRESS DATABASE`, `RECOMPRESS TABLE` does not commit by itself, so keep autocommit enabled. While a table is being processed, it is write-locked: concurrent writes to that table wait until it is committed or fail with a transaction conflict. Expect some performance impact, and avoid heavy queries during `REORGANIZE`.

**Do the savings last?** Yes. New data uses the new compressors automatically. Heavy updates and deletes can degrade compression over time. `REORGANIZE` without `ENFORCE` takes care of tables that need it.

**Does it reduce my license usage?** Only where sizing is based on memory or compressed data. The uncompressed (raw) data size does not change.

## Additional References

* Changelog: [Activate new block compressors](https://docs.exasol.com/db/latest/changelogs/26664.htm)
* Changelog: [Improve compression of columns with 32K to 64K distinct values](https://docs.exasol.com/db/latest/changelogs/26225.htm)
* SQL reference: [RECOMPRESS](https://docs.exasol.com/db/latest/sql/recompress.htm)
* SQL reference: [REORGANIZE](https://docs.exasol.com/db/latest/sql/reorganize.htm)
* System table: [EXA_DBA_OBJECT_SIZES](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_dba_object_sizes.htm)
* System table: [EXA_DB_SIZE_LAST_DAY](https://docs.exasol.com/db/latest/sql_references/system_tables/statistical/exa_db_size_last_day.htm)
* Knowledge Base: [What to do when I see differences between database size or storage space increases steadily](/Database-Features/what-to-do-when-i-see-differences-between-database-size-or.md)
* Knowledge Base: [How to estimate the duration of REORGANIZE DATABASE when enlarging a cluster](/Database-Features/how-to-estimate-duration-of-reorganize-database-when-enlarging-a.md)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
