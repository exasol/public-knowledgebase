# Slow Index Build Factors 
## Overview

This article draws on past questions from our user base and is an extension of articles such as [Performance Best Practices](https://docs.exasol.com/performance/best_practices.htm), and [Indexes](https://exasol.my.site.com/s/article/Indexes). We will explain how slow index builds occur and provide tips on how to avoid them. To keep this article within scope, we are not covering in much detail JOINs or Best Practices. You can find more in our [Community](https://community.exasol.com/).

## Question:

On a single-node cluster, a table with two columns (with a certain range of values) seems to take about a minute per 100M rows to create an index. Why is this causing some SELECTs to timeout when they auto-create the index for large tables (hundreds of millions of rows)?

### Terminology

1. DB_RAM refers to the local size of DBRAM on a single node.

The current size of DBRAM is stored in the column DB_RAM_SIZE of the system table EXA_SYSTEM_EVENTS. If you want to know the share of DBRAM per node you simply have to divide DB_RAM_SIZE by NODES (also stored in EXA_SYSTEM_EVENTS).

2. Distribution columns and Distribution keys mean the same thing.

3. "Root" table refers to the first table analyzed in a JOIN. The "Target" table(s) refers to the tables that receive a new index(es) to be matched against the "Root" table. 

## Answer:

This is a two-part response. *Answer A* looks at hardware limitations and *Answer B* looks at workload impacts. We are covering the “general” slow index build aspect. A more complete narrative can be found in the links provided at the bottom of this article.

## Answer A: Looking at Hardware Limitations

Index creation in general uses a considerable amount of DB_RAM, your active database memory. It's divided up between active data and temporary data, to clarify, persistent data and temporary, or generated data. In DB_RAM, the ratio between active data and temp data is flexible, but temp data is limited to 80% of DB_RAM capacity. Your DB_RAM can be found in EXA_SYSTEM_EVENTS. For more information, see [Exasol memory management](https://exasol.my.site.com/s/article/Overview-of-Exasol-s-data-and-memory-management).

To keep the database operational at high speed only a fixed portion of DB_RAM is used for index creation. As mentioned, the size of the reserved memory is relative to DB_RAM size. In case all elements fit into the reserved memory, only one single iteration is enough to create the index. If the number of elements exceeds the size of the memory, at least two iterations are necessary.

The first-row range iteration is the fastest as the existing index is nil. Most of the work can be done in parallel. However, the degree of parallel execution of the second iteration shrinks significantly: inserts are performed into an existing data structure, block/nodes are split, and some parts of the index are reorganized. This has to be done sequentially in most parts and is thus much slower.

For the single node configuration, the cutting edge is at a row size of approx. 514m elements. If you add more DB_RAM (e.g., by adding more nodes) more elements can be processed in a single iteration. By doubling the size of the DB_RAM of the node you used for the measurements, a second iteration will be necessary at approx. 1.2 billion row elements.

## Answer B: Looking at Workload Impacts.

This section looks at queries that build first-time indexes, followed by miscellaneous factors impacting indexes.

1. The first time you run a “new” query with a JOIN in it, Exasol builds the needed indexes based on how it optimizes the query. When the query completes successfully, the new index is externalized or made persistent. The next time a query does a join, there is no index build overhead – hence faster. More information can be found [here](https://exasol.my.site.com/s/article/Indexes). The point is that the initial execution of your new JOIN SQL will contain an extra step shown in the profile table, "INDEX CREATION".
2. Joining columns of different data types builds a temporary “Expression” Index. To clarify, if the join column DATATYPES are NOT the same between each table, a temporary expression index is built. Expression indexes are built every time you run the JOIN query, regardless of whether the query completes successfully. More information and an example can be found within the article [Decimal Joins](https://exasol.my.site.com/s/article/What-happens-when-I-JOIN-DECIMAL-datatypes-of-various-sizes?) and [DataTypes and Joins](https://exasol.my.site.com/s/article/Best-practice-Datatypes-and-Joins).

3. Joins that are not using distribution keys will result in a “global join”, whereas joining on a distribution key results in a “local join’. Local JOINS are more efficient and can take further advantage of parallelism. You can find additional information on this here [Local-and-global-joins](https://exasol.my.site.com/s/article/Local-and-Global-Joins).  If your WHERE (filtering) clause contains a distribution column, it will revert to a global join and will NOT take advantage of parallelism. For additional information, see [Distribution keys](https://www.exasol.com/resource/how-to-get-distribution-right-in-our-analytics-database/). 

4. During an index build, if you insert into the table which is being indexed, you will negate the in-play index build and will recalculate after the insert commits.
5. The Cost-Based Optimizer can be influenced to force join order. Essentially, we want the JOIN process to start with the smaller of the two tables (the "Root" table) being joined to minimize the joining composite recordset. Actually, your "Root" table can be the largest table, if the WHERE (filtering) clause has the most stringent filtering of all the tables being joined. You can see an SQL example of processing inefficient information [here](https://docs.exasol.com/performance/profiling.htm). Some additional actions can be:
* Add an ORDER-BY-FALSE to force materialization, See [Enforce Materializations](https://exasol.my.site.com/s/article/Enforcing-materializations-with-ORDER-BY-FALSE-in-subselects-views-or-CTEs)
* Rewrite an INNER JOIN as a LEFT JOIN WHERE NOT-NULL to influence join order.
* Enforce the JOIN order using "control set join order". For example: 
```sql
CONTROL SET JOIN ORDER T2,T1;
```

**Note:** If your tables are aliased, then the **CONTROL SET JOIN ORDER** should refer to the **aliases.**

## Additional References

[Index maintenance](https://exasol.my.site.com/s/article/Indexes)

[Best Practice: Datatypes and Joins](https://exasol.my.site.com/s/article/Best-practice-Datatypes-and-Joins)

[Performance Best Practices](https://docs.exasol.com/performance/best_practices.htm)

[Distribution keys](https://www.exasol.com/resource/how-to-get-distribution-right-in-our-analytics-database/)

[Enforce Materializations](https://exasol.my.site.com/s/article/Enforcing-materializations-with-ORDER-BY-FALSE-in-subselects-views-or-CTEs)

[Preloading indexes](https://docs.exasol.com/sql/preload.htm.)

[Profiling](https://docs.exasol.com/performance/profiling.htm)

[Exasol memory management](https://exasol.my.site.com/s/article/Overview-of-Exasol-s-data-and-memory-management)

