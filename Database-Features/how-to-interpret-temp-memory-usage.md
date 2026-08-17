# How to Interpret TEMP Memory Usage

## Question

How can you interpret the `TEMP_DB_RAM` values in Exasol system tables? Why can the sum of `EXA_DBA_SESSIONS.TEMP_DB_RAM` values differ from `EXA_MONITOR_LAST_DAY.TEMP_DB_RAM`?

## Answer

Exasol reports temporary memory at different levels. The values are useful together, but they should not be compared as if they were measurements with the same scope and aggregation.

### Session-level TEMP memory

`EXA_DBA_SESSIONS.TEMP_DB_RAM` reports the current temporary database memory usage of each open session in MiB. The value is cluster-wide for that session.

Use this view to identify which currently open sessions are using temporary memory:

```sql
SELECT session_id,
       user_name,
       cluster_name,
       status,
       command_name,
       temp_db_ram
FROM exa_dba_sessions
WHERE temp_db_ram > 0
ORDER BY temp_db_ram DESC;
```

To calculate the current session-level usage by cluster, you can use:

```sql
SELECT cluster_name,
       SUM(temp_db_ram) AS session_temp_db_ram,
       COUNT(*) AS sessions
FROM exa_dba_sessions
GROUP BY cluster_name
ORDER BY cluster_name;
```

This is a **live snapshot**. It changes as sessions start and finish statements, release intermediate results, fetch data, or disconnect.

### Cluster-level monitor TEMP memory

`EXA_MONITOR_LAST_DAY.TEMP_DB_RAM` contains periodically sampled cluster monitoring data. Each row is identified by `CLUSTER_NAME` and `MEASURE_TIME` and represents the database state at that measurement time.

The public monitor value is a cluster-scaled value derived from the maximum node usage. It is not the raw TEMP value of one node and it is not the sum of all `EXA_DBA_SESSIONS` rows. The value also accounts for process memory that is part of the database memory usage reported by the monitor.

Use it to identify cluster-wide memory pressure and historical peaks:

```sql
SELECT cluster_name,
       measure_time,
       temp_db_ram
FROM exa_monitor_last_day
WHERE measure_time >= ADD_HOURS(CURRENT_TIMESTAMP, -1)
ORDER BY cluster_name,
         measure_time;
```

### How the values are calculated

The two values use different aggregation paths. The following diagram shows the conceptual calculation. `MAX` is applied across nodes, `SUM` is applied across processes or sessions, and `NPROC()`/`NODES` scales a per-node result to the cluster.

Reasoning behind the `MAX` metric is simple: In an Exasol cluster, the "worst" node will usually determine overall performance.

For simplification reasons, `TEMP DBRAM` (managed swappable data blocks) and `HEAP` (dynamic process memory) are combined into a single
value for reporting &mdash; both effectively reduce the amount of DBRAM available for persistent data.

#### EXA_DBA_SESSIONS.TEMP_DB_RAM

For each logical session or process:

```text

    temporary DB RAM on each node 
           └── MAX across nodes ───┐
    process memory on each node    ├── add
           └── MAX across nodes ───┘    │
                                        │
                                        └── multiply by NPROC()
                                            │
                                            └── one TEMP_DB_RAM value per session row
```

#### EXA_MONITOR_LAST_DAY.TEMP_DB_RAM

For each measurement time:

```text
    node 1: SUM(temporary DB RAM over monitored processes)
    node 2: SUM(temporary DB RAM over monitored processes)
    ...
    node N: SUM(temporary DB RAM over monitored processes)
              │
              └── MAX across nodes = TEMP_DB_RAM_MAX

    node 1: SUM(process memory over monitored processes)
    node 2: SUM(process memory over monitored processes)
    ...
    node N: SUM(process memory over monitored processes)
              │
              └── MAX across nodes = MEM_MAX

    (TEMP_DB_RAM_MAX + MEM_MAX) × NPROC()
              │
              └── EXA_MONITOR_LAST_DAY.TEMP_DB_RAM
```

### In simplified formula form

```text
SUM(EXA_DBA_SESSIONS.TEMP_DB_RAM)
  = SUM across sessions of (
        (MAX across nodes of session temporary DB RAM
       + MAX across nodes of session process memory)
        × NPROC()
    )

EXA_MONITOR_LAST_DAY.TEMP_DB_RAM
  = (
        MAX across nodes of SUM across monitored processes of temporary DB RAM
      + MAX across nodes of SUM across monitored processes of process memory
    ) × NPROC()
```

The two expressions are not interchangeable. In particular, the node with the highest temporary DB RAM can differ from the node with the highest process memory. The monitor expression takes those maxima independently. Also, the sum of per-process maxima is generally different from the maximum of per-node process sums.

- `EXA_DBA_SESSIONS` May overesitimate on process level &mdash; while data processing and memory allocation are typically well-balanced, some skew may occur.
- `EXA_MONITOR_LAST_DAY` smoothes values over individual processes, but it does include heap usage of the service processes (object server, pdd server), which may also be substantial for systems with many database objects.

## Additional References

- **Documentation:** [Statistical system tables](https://docs.exasol.com/sql_references/metadata/statistical_system_table.htm)
- **Documentation:** [EXA_DBA_SESSIONS system table](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_dba_sessions.htm)
- **Article:** [EXA_STATISTICS](https://exasol.my.site.com/s/article/EXA-STATISTICS)
- **Article:** [Monitoring of an Exasol Database](https://exasol.my.site.com/s/article/Monitoring-of-an-Exasol-Database)
- **Article:** [Analyzing disk I/O and concurrency based on *_last_day data](https://exasol.my.site.com/s/article/Analyzing-disk-I-O-and-concurrency-based-on-last-day-data)
- **Article:** [Overview of Exasol's data and memory management](https://exasol.my.site.com/s/article/Overview-of-Exasol-s-data-and-memory-management)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
