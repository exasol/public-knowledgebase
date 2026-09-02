# Using the STANDARD and LEGACY Join Optimizers

## Purpose

Exasol provides two join-order optimizers:

- **STANDARD**
- **LEGACY**

The **STANDARD** optimizer is the preferred default starting from Exasol v8 and should normally be used for workloads.

The **LEGACY** optimizer remains available in v8 as an alternative for individual queries where it produces a more efficient execution plan.

## Scope

No optimizer can produce the best possible execution plan for every query.

In rare cases, the STANDARD optimizer can choose an inefficient join order, for example by executing high fan-out joins before a highly selective join. This can create very large intermediate result sets and significantly increase execution time.

In such cases, testing the same query with the LEGACY optimizer is a valid optimization approach.

The recommended strategy is:

1. Keep **STANDARD** as the default.
2. Profile the slow query.
3. If join order appears inefficient, compare STANDARD and LEGACY.
4. If LEGACY performs consistently better, use LEGACY only for the affected query where possible.

Both optimizers are intended to remain available, while STANDARD remains the primary optimizer for future development.

<!-- UNVERIFIED: Confirm the long-term product commitment for keeping both optimizers before external publication. -->

## Core concepts

### Prefer STANDARD

Use STANDARD for normal query execution.

It is the newer optimizer architecture and remains the preferred choice overall.

### Use LEGACY for individual tuning cases

Consider LEGACY when profiling shows that STANDARD creates an inefficient join order.

Typical indicators include:

- very large intermediate result sets;
- high fan-out joins executed too early;
- selective joins executed too late;
- excessive index or synchronization costs;
- a significant and reproducible runtime improvement with LEGACY.

If only one query benefits from LEGACY, do not switch the entire database.

## Switching between optimizers

You can switch optimizers at different scopes.

### 1. Query level

Use **join optimizer** hints right before the query to force a specific optimizer version for this query only.
This is the preferred approach for individual query tuning.

To force LEGACY:

```sql
/*join optimizer legacy*/
SELECT ...;
```

To force STANDARD:

```sql
/*join optimizer standard*/
SELECT ...;
```

### 2. Session level

Use this approach when testing several queries in the same session.

```sql
-- Switch session to LEGACY
CONTROL SET JOIN OPTIMIZER LEGACY;

-- Switch back to STANDARD:
CONTROL SET JOIN OPTIMIZER STANDARD;

-- Return to the database default:
CONTROL CLEAR JOIN OPTIMIZER;
```

### 3. Database level

The LEGACY optimizer can also be configured database-wide with database parameter:

```sh
-joinOrderMethod=0
```

This requires a database restart and affects all sessions that do not override the setting.
Use database-wide switching only when workload-level testing shows a clear benefit.

## Additional References

- [Activation of new Join Order Optimizer by default](https://docs.exasol.com/db/latest/changelogs/12517.htm)
- [Add query prefix to switch optimizers](https://docs.exasol.com/db/latest/changelogs/27990.htm)
