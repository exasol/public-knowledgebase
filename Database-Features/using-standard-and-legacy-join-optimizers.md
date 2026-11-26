---
doc_type: concept
category: "Database Features"
title: "Using the STANDARD and LEGACY Join Optimizers"
summary: "Choose between STANDARD and LEGACY join-order optimizers and manage query, session, and database-wide overrides."
version: 8.x
needs_review: no
tags: [optimizer, performance, joins]
keywords: [standard, legacy, joinordermethod, profiling]
---

# Using the STANDARD and LEGACY Join Optimizers

## Purpose

Exasol provides two join-order optimizers:

- **STANDARD**
- **LEGACY**

The **STANDARD** optimizer is the preferred default starting from Exasol v8 and should normally be used for workloads.

The **LEGACY** optimizer remains available in v8 as an alternative for individual queries where it produces a more efficient execution plan.

## Scope

**Exasol also performs other query optimizations, such as rule-based transformations; this article and the settings described here apply only to join-order optimization.**

No optimizer can produce the best possible execution plan for every query.

For some queries, the STANDARD join-order optimizer can choose an inefficient join order, for example by executing high fan-out joins (joins that multiply the number of rows) before a highly selective join. This can create very large intermediate result sets and significantly increase execution time.

In such cases, testing the same query with the LEGACY  join-order optimizer is a valid optimization approach.

The recommended strategy is:

1. Keep **STANDARD** as the default.
2. Profile the slow query.
3. If join order appears inefficient, compare STANDARD and LEGACY.
4. If LEGACY performs consistently better, use LEGACY only for the affected query where possible.

Some improvements to join-order optimization are implemented only in STANDARD.

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

### Comparing database-wide strategies

You can use either optimizer as the database default and select the other optimizer for individual queries.

| Aspect | LEGACY as the database default; STANDARD for selected queries | STANDARD as the database default; LEGACY for selected queries |
| --- | --- | --- |
| Immediate advantage | Limits the initial change if most existing queries already perform well with LEGACY. | Requires few exceptions if most queries already perform well with STANDARD. |
| Main trade-off | Queries without overrides continue to use LEGACY. Further queries need testing and explicit overrides to use STANDARD. | Queries without overrides use STANDARD immediately. Investigate regressions and add targeted LEGACY overrides where needed. |
| Future STANDARD improvements | Apply to queries explicitly using STANDARD. Other queries continue to use LEGACY. | Apply to queries using STANDARD, including those without overrides. Explicit LEGACY overrides continue to select LEGACY. |
| Ongoing maintenance | Reassess which additional queries benefit from STANDARD. | Reassess whether existing LEGACY exceptions are still necessary. |
| If all queries later perform better with STANDARD | Change the database default to STANDARD. Existing STANDARD prefixes can remain; they become redundant. | Retest and remove remaining LEGACY prefixes. Changing the database default does not override an explicit query prefix. |

This comparison assumes that no session-level setting overrides the database default.

**Query prefixes take precedence over session and database defaults.** An explicit LEGACY prefix continues to select LEGACY after a database update. It does not automatically switch to STANDARD when STANDARD improves.

For a workload with only a few known exceptions, prefer STANDARD as the default with targeted LEGACY prefixes. If testing reveals many unresolved regressions, keeping LEGACY as the default can be a temporary transition strategy.

For either strategy:

- Record each exception, its reason, the tested database version, and the measured runtimes.
- Retest exceptions after relevant database updates.
- Remove overrides when they no longer provide a consistent benefit.

The last row describes a possible future scenario, not a guarantee: STANDARD is not guaranteed to become faster for every query.

## Switching between optimizers

You can switch optimizers at different scopes.

### 1. Query level

**Execution context: DB (SQL).**

Use an exact **join optimizer** prefix at the beginning of the SQL statement to select a join-order optimizer for that query only. Preserve the spelling and spacing inside the prefix.

This is the preferred approach for individual query tuning.

To force LEGACY:

```sql
/*join optimizer legacy*/
SELECT ...;
```

The query uses LEGACY, regardless of the session or database default.

To force STANDARD:

```sql
/*join optimizer standard*/
SELECT ...;
```

The query uses STANDARD, regardless of the session or database default.

### 2. Session level

**Execution context: DB (SQL).**

Use this approach when testing several queries in the same session.

```sql
-- Switch the session to LEGACY.
CONTROL SET JOIN OPTIMIZER LEGACY;

-- Switch the session to STANDARD.
CONTROL SET JOIN OPTIMIZER STANDARD;

-- Return to the database default.
CONTROL CLEAR JOIN OPTIMIZER;
```

Each setting applies to subsequent queries in the session unless a query prefix overrides it. Clearing the setting restores the database default.

### 3. Database level

**Configuration scope: DB startup parameter, applied through your deployment's administration tools.**

You can configure the LEGACY optimizer database-wide with the following database parameter. This is a configuration value, not a standalone shell command.

Changing this startup parameter requires a database restart. Plan the resulting interruption before applying the change.

```text
-joinOrderMethod=0
```

After the restart, LEGACY applies to sessions and queries that do not override the database setting.

Use database-wide switching only when workload-level testing shows a clear benefit.

## Additional References

- [Activation of new Join Order Optimizer by default](https://docs.exasol.com/db/latest/changelogs/12517.htm)
- [Add query prefix to switch optimizers](https://docs.exasol.com/db/latest/changelogs/27990.htm)

