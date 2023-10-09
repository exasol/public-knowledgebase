# Replication border in Exasol 6.0 
## Question

What is a smart table replication and how can the replication border be modified?

## Answer

## General information on smart table replication

* Replicates are used "on-the-fly" for local joins if a table is "small" regarding the threshold.
* A replicated table accesses data directly from other nodes' database memories and keeps a local copy in its own DBRAM.
* If a replicated table is modified, only changed data is reloaded into database memories of other nodes.
* Modified tables and subselects cannot be used with smart table replication. Table replication border does not apply to those.
* Using large replicated tables might cause decreased performance. Queries with expensive table scans (filter expressions) or between / cross joins may fall into this category.

## Soft replication border

A table will be replicated if none of the thresholds below are reached. The table size threshold refers to the RAW_OBJECT_SIZE like in EXA_*_OBJECT_SIZES.  
The replication borders can be modified through **extra database parameters** in the web interface:


```
-soft_replicationborder_in_numrows=<numrows> [default is 100000 rows] 
-soft_replicationborder_in_kb=<kb> [default is 1000000 -> 1GB]
```
## Additional References

* [replication-border-in-exasol-6-1](https://exasol.my.site.com/s/article/Replication-border-in-Exasol-6-1)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 