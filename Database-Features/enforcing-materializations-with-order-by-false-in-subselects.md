# Enforcing materializations with ORDER BY FALSE in subselects, views or CTEs 
Sometimes it is useful to enforce a materialization of a subselect (or view or CTE) by adding an ORDER BY FALSE to it.  
Those cases include:

1. Late applied filter (see attached, pdf)
2. Replace global by local join (by enforcing a materialization of a subselect that is smaller than replication border [see [replication-border-in-exasol-6-1](https://community.exasol.com/t5/database-features/replication-border-in-exasol-6-1/ta-p/1727)] with local filters)
3. Manual precalculation of multiple usages of subselects, views, CTEs

Please be aware that materializations can cause a lot of temporary data if they are big which might result in block swapping and decrease thoughput

The attached documents show when a subselect, view or CTE needs to be materialized  01_Materializations.pdf 

and a use case to improve performance 02_OptimizationExampleMaterialization.pdf 

Those documents require some knowledge about [profiling](https://community.exasol.com/t5/database-features/how-to-explain-query-performance-using-profiling/ta-p/1608) .

