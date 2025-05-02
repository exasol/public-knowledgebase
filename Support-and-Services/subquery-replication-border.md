# Subquery Replication Border

## Background

Concept of the replication border and corresponding DB parameter `-soft_replicationborder_in_numrows` are described here:

- [Best Practices](https://docs.exasol.com/db/latest/performance/best_practices.htm)  
- [Replication border in Exasol 6.1](https://exasol.my.site.com/s/article/Replication-border-in-Exasol-6-1)
- [Replication border in Exasol 8](https://exasol.my.site.com/s/article/Changelog-content-16000)

But `-soft_replicationborder_in_numrows` only works for persistent tables, for temp tables and materializations it doesn't.
However, there is another undocumented parameter `-subqueryreplicationborder` which plays exactly the same role but only for subquery's temp tables.

- When the Optimizer decides if a subquery or materialized table should be replicated, it uses the subquery replication border parameter. It also defaults to 100000 and can be explicitly altered by using the command-line parameter `-subqueryreplicationborder`, same way as with the standard replication border.
- Increasing this parameter can lead to higher DBRAM usage, which may affect the system's behavior. In some cases, this can result in excessive memory consumption and overall system slowdown. Therefore, please adjust this setting with caution.
- IMPORTANT: This is an undocumented parameter, so we cannot guarantee that its behavior will remain unchanged in the future. However, it has been confirmed that there are no plans to modify this behavior in version 8.
- In v8 the proper way of changing `-soft_replicationborder_in_numrows` is ALTER SYSTEM command instead of DB parameter. But for the `-subqueryreplicationborder` the same is not provided. So the only way of changing it remains DB parameter.

## How to adjust SubqueryReplication border

The replication borders can be modified through extra database parameters:

```sh
-subqueryreplicationborder=<numrows> [default is 100000 rows]
```

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
