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

An upgrade does not rewrite your tables. Data loaded after the upgrade uses the new compressors, but historical data stays as it was. Large fact tables and archives that are rarely modified are where the savings are biggest, and they never pick up the new compressors on their own.

Two SQL statements fix that:

* [`RECOMPRESS ... ENFORCE`](https://docs.exasol.com/db/latest/sql/recompress.htm) re-encodes every column with the best compressor now available. Without `ENFORCE`, Exasol only recompresses columns where it expects a significant improvement.
* [`REORGANIZE ... ENFORCE`](https://docs.exasol.com/db/latest/sql/reorganize.htm) rewrites the table data, removes rows that are only marked as deleted, recompresses degraded columns, and recreates internal indexes. Running it after `RECOMPRESS` gives the best result.

### What you gain

Recompression shrinks the compressed size of your data (`MEM_OBJECT_SIZE`). The uncompressed size (`RAW_OBJECT_SIZE`) stays the same and therefore does not have an impact on your raw data size license. In field deployments, the compressed size dropped by roughly 20% to 40%, depending on the data.

* **More data in memory.** Exasol processes compressed data in RAM, so the same DB RAM holds a larger share of your working set and fewer reads go to disk.
* **Faster queries on large tables.** There is less data to scan, less I/O per query, and freshly recreated indexes.
* **Less disk space.** Storage usage drops, which postpones the next storage expansion.
* **Smaller, faster backups.** Backups copy the compressed data blocks, so full and incremental backups shrink and finish faster. The gain is somewhat smaller than the compression gain, because backups receive additional compression on their way to the archive volume.
* **Lower recommended DB RAM.** The recommended DB RAM is derived from the compressed size, which helps with sizing and capacity planning.
* **Cleaner tables.** Rows that were only marked as deleted are removed.

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
| Free disk space | New blocks are written before the old ones are released, so the operation temporarily needs extra space. Make sure free storage comfortably exceeds the compressed size of your largest schema. If it does not, expand storage first. Working schema by schema, smallest first, keeps the peak low. |
| Backups | Take a backup before you start, and run a full backup (level 0) immediately after the operation. Because almost every block is rewritten, an incremental backup would be nearly as large as a full one. Old blocks are only released on disk once the older backups that still reference them expire. |
| Timing | Expect anything from minutes to many hours, depending on data volume and I/O. The operation runs alongside normal workload with a moderate performance impact, but large queries during `REORGANIZE` can slow it down. A night or weekend window is ideal. |
| Privileges | `USE ANY SCHEMA` (or `USAGE` on the schema) plus a modifying `ANY TABLE` system privilege, a modifying object privilege, or ownership of the affected tables. Reading `EXA_DBA_OBJECT_SIZES` and `EXA_DBA_SESSIONS` requires `SELECT ANY DICTIONARY`. |
| Session | Use a session that does not time out, such as EXAplus inside `screen` or `tmux`, or a scheduled job. |

## How to recompress your data after the upgrade

All statements in this section run in the database (SQL). `EXA_DBA_OBJECT_SIZES` reports bytes, and `EXA_DB_SIZE_LAST_DAY` reports GiB.

### Step 1: Record a baseline

Run the following queries and keep the output so you can compare the results afterwards.

```sql
-- Database totals (latest measurement)
SELECT MEASURE_TIME,
       RAW_OBJECT_SIZE                             AS RAW_GIB,
       MEM_OBJECT_SIZE                             AS MEM_GIB,
       ROUND(RAW_OBJECT_SIZE / MEM_OBJECT_SIZE, 2) AS COMPRESSION_RATIO,
       RECOMMENDED_DB_RAM_SIZE                     AS RECOMMENDED_DB_RAM_GIB,
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
  FROM EXA_DBA_OBJECT_SIZES
 WHERE OBJECT_TYPE = 'SCHEMA'
   AND NOT OBJECT_IS_VIRTUAL
   AND MEM_OBJECT_SIZE > 0
 ORDER BY MEM_OBJECT_SIZE DESC;
```

The first query returns one row with the database totals. The second query returns one row per schema, largest first.

### Step 2: Check free space

```sql
-- Check free space
SELECT d.STORAGE_SIZE                                        AS STORAGE_GIB,
       ROUND(d.STORAGE_SIZE * (100 - d.USE) / 100, 1)        AS FREE_GIB,
       ROUND(MAX(o.MEM_OBJECT_SIZE) / 1024 / 1024 / 1024, 1) AS LARGEST_SCHEMA_MEM_GIB
  FROM (SELECT * FROM EXA_STATISTICS.EXA_DB_SIZE_LAST_DAY
         ORDER BY MEASURE_TIME DESC LIMIT 1) d
 CROSS JOIN EXA_DBA_OBJECT_SIZES o
 WHERE o.OBJECT_TYPE = 'SCHEMA'
   AND NOT o.OBJECT_IS_VIRTUAL
 GROUP BY d.STORAGE_SIZE, d.USE;
```

The query returns one row with the total storage, the free storage, and the compressed size of your largest schema, all in GiB.

Continue when `FREE_GIB` comfortably exceeds `LARGEST_SCHEMA_MEM_GIB`. On Exasol SaaS, `STORAGE_SIZE` can be empty. In that case, check free space in the SaaS console instead.

### Step 3: Take a backup

Take a backup before you change any data. For on-premises installations, see [Backup and restore](https://docs.exasol.com/db/latest/administration/on-premise/backup_restore.htm). On Exasol SaaS, use the backup options in the SaaS console.

### Step 4: Generate and run the script, smallest schema first

**Warning:** The statements temporarily need extra disk space, because new blocks are written before the old ones are released. If storage fills up, the database can no longer write data. Make sure you completed Step 2, and keep an eye on storage usage while the script runs.

Generate one line per schema:

```sql
-- Generate commands, 1 line per schema
SELECT 'RECOMPRESS SCHEMA "' || OBJECT_NAME || '" ENFORCE; COMMIT; '
    || 'REORGANIZE SCHEMA "' || OBJECT_NAME || '" ENFORCE; COMMIT; '
    || 'FLUSH STATISTICS; COMMIT;' AS REORG_COMMAND
  FROM EXA_DBA_OBJECT_SIZES
 WHERE OBJECT_TYPE = 'SCHEMA'
   AND NOT OBJECT_IS_VIRTUAL
 ORDER BY MEM_OBJECT_SIZE, OBJECT_NAME;
```

The query returns one line per schema, smallest schema first. Run the generated lines in order. Each line looks like this:

```sql
RECOMPRESS SCHEMA "SALES" ENFORCE; COMMIT; REORGANIZE SCHEMA "SALES" ENFORCE; COMMIT; FLUSH STATISTICS; COMMIT;
```

For a very large schema, work table by table instead. This keeps each unit of work, its disk peak, and its transaction small:

```sql
-- Generate commands, 1 line per table
SELECT 'RECOMPRESS TABLE "' || ROOT_NAME || '"."' || OBJECT_NAME || '" ENFORCE; COMMIT; '
    || 'REORGANIZE TABLE "' || ROOT_NAME || '"."' || OBJECT_NAME || '" ENFORCE; COMMIT;' AS REORG_COMMAND
  FROM EXA_DBA_OBJECT_SIZES
 WHERE OBJECT_TYPE = 'TABLE'
   AND ROOT_NAME   = 'MY_BIG_SCHEMA'   -- replace with your schema
 ORDER BY MEM_OBJECT_SIZE, OBJECT_NAME;
```

The query returns one line per table in the schema, smallest table first. Run the generated lines in order.

### Step 5: Monitor progress

Check the running statements, and keep an eye on storage usage:

```sql
-- Monitor progress
SELECT SESSION_ID, USER_NAME, STATUS, DURATION, ACTIVITY, SQL_TEXT
  FROM EXA_DBA_SESSIONS
 WHERE UPPER(SQL_TEXT) LIKE 'RECOMPRESS%'
    OR UPPER(SQL_TEXT) LIKE 'REORGANIZE%';
```

The query returns one row for each session that is running `RECOMPRESS` or `REORGANIZE`. `ACTIVITY` shows the current operation, and `DURATION` shows how long the statement has been running. When the query returns no rows, the script has finished.

### Step 6: Run a full backup

As soon as the last statement has committed, run a full backup (level 0) and confirm that it completes successfully. This step is mandatory. Almost every data block is new after the operation, so a full backup creates a clean restore baseline on the new layout and lets the older backups, and the old blocks they reference, expire.

### Step 7: Compare the results

A few hours later, run the Step 1 queries again. Compare the compressed size, compression ratio, and recommended DB RAM with your baseline. Compare the size and duration of the new full backup with the previous one.

## Additional Notes

**I already use 2025.1.3 or later and am upgrading to 2026.1. Do I need to run this again?** Not because of the upgrade. The new compressors have been available since 2025.1.3, so upgrading to 2026.1 does not add new ones. If you have not recompressed your data since you upgraded to 2025.1.3 or later, run the procedure now. Otherwise, repeat it as usual every few months.

**Why use `ENFORCE`?** Without it, Exasol skips columns where it does not expect a significant improvement, so much of your older data keeps the old compressors.

**Why run `REORGANIZE` if no nodes were added?** Besides redistributing data, `REORGANIZE` removes rows that are only marked as deleted, recompresses degraded columns, and recreates indexes. Running `RECOMPRESS` followed by `REORGANIZE` consistently gives the best result.

**Schema by schema, or `RECOMPRESS DATABASE`?** Schema by schema. Smaller units keep the disk peak and the lock time per object low, let you pause between schemas, and make progress visible. The database-wide statements work, but run as one long operation.

**Is it safe to run while users are working?** Yes, but plan for it. `RECOMPRESS SCHEMA` runs as one transaction per schema, so concurrent writes to that schema can conflict or wait until it commits. `REORGANIZE` commits after each table, so its locks are short. Expect some performance impact, and avoid heavy queries during `REORGANIZE`. For busy schemas, use the table-by-table script from Step 4.

**Do the savings last?** Mostly. New data uses the new compressors automatically. Heavy updates and deletes degrade compression again over time, so repeating the procedure every few months, followed by a full backup, keeps compression optimal.

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
