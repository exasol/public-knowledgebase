# Indexes 
## Background

## Index creation

Indexes are automatically generated, reutilized, and discarded by the system as necessary. The user can not directly influence this, indexes will be automatically created during the execution of queries or statements like MERGE containing an equality join, as long as it completed successfully and didn't rollback.

Indexes will be stored persistently and reused in later executions. Indexes are stored in a compressed manner and don't need to be decompressed when accessing them. Indexes are used for joins and under certain circumstances for filtering the data of a table (index scan).  
Internally, Exasol is using a highly tuned B-tree structure.

#### Expression Index

Assuming the join, 


```"noformat
... A join B on round(A.x) = B.x ...
```
an index might have to be built on table A, based on the given expression. Such an index will NOT be stored persistently but will be dropped after query execution. It follows that this index will have to be rebuilt every time a join of this type is being performed.

## Explanation

## Index maintenance

Table changes (caused by INSERT or DELETE) are incrementally integrated into existing indexes. UPDATE on columns with an index will be integrated into the index unless:

* the number of updated rows of the corresponding table exceeds a certain limit
* the column is part of the distribution key

In these cases, the index will be rebuilt from scratch during the UPDATE statement.

In other words - If Data Manipulation Language (DML) is done on t1, the index is maintained by the system:

* INSERT into t1 will add new index entries.
* DELETE from t1 will mark rows as deleted until more than 25% of rows have been deleted. t1 is then [reorganized automatically](https://uhesse.com/2018/08/17/automatic-table-reorganization-in-exasol/) and the index is automatically rebuilt.
* UPDATE statements that affect less than 15% of rows will update index key entries. If more than 15% of rows are updated, the index is automatically rebuilt.

If an index is not accessed, it will simply be removed from memory and reside on hard disc. If the index won't be accessed (read) for a certain period of time (35 days), it will be automatically dropped.

## Visibility

The overall amount of indexes is reflected by AUXILIARY_SIZE*-columns of EXA_DB_SIZE_* tables.   
In Version 5 system tables showing detailed information - including size - for all indices were introduced: EXA_DBA_INDICES, EXA_ALL_INDICES, EXA_USER_INDICES

## Index types

In Exasol, there are two different types of indexes: GLOBAL and LOCAL indexes depending on the join type (see [Local-and-Global-joins](https://exasol.my.site.com/s/article/Local-and-Global-Joins)). Like tables, indices are stored in a distributed fashion across the cluster.

#### LOCAL index

A local index stores information on a per-node basis: Given a local index on (A.x), the index part on node 1 will only contain references to rows of A that are stored on node 1.  
Local indices are perfect for table scans and local joins, as all information is available without requiring network traffic.

#### GLOBAL index

A global index stores information on a per-table basis, but behaves like a table with a distribution key: All references to a certain key are stored on a well-defined node in the cluster, even if the rows referenced reside on different or multiple nodes.  
If a distribution key is set on the table and the index contains all columns of that distribution key, the index will be distributed in line with the table, effectively making it a local index.

## Additional References

[Local-and-Global-joins](https://exasol.my.site.com/s/article/Local-and-Global-Joins?search-action-id=2672626244&search-result-uid=1297 "This") 

[Does-Exasol-index-nulls](https://exasol.my.site.com/s/article/Does-Exasol-index-NULLS??search-action-id=2672652107&search-result-uid=1243) 

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 