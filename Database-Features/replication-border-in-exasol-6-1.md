# Replication border in Exasol 6.1 
## Question

What is a replicated table and how can the replication border be modified?

## Answer

* Replicates are used "on-the-fly" for local joins if a table is "small" regarding the threshold.
* A replicated table accesses data directly from other nodes' database memories and keeps a local copy in its own DBRAM.
* If a replicated table is modified, only changed data is reloaded into database memories of other nodes.
* Modified tables and subselects cannot be used with smart table replication. Table replication border does not apply to those.
* Using large replicated tables might cause decreased performance. Queries with expensive table scans (filter expressions) or between / cross joins may fall into this category.

#### Replication border

A table will be joined by smart table replication if it has fewer or equal rows than the threshold below.  
The replication borders can be modified through**extra database parameters**in the web interface:


```"code-java"
-soft_replicationborder_in_numrows=<numrows> [default is 100000 rows]
```
