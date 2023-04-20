# Bad data distribution after cluster enlargement 
## Background

* After a cluster enlargement, performance may not increase as expected or even decrease.
* Profile of affected queries shows strong data imbalance (NODE SYNC) and possibly disc access

## Additional Notes

This may be caused by the semantics of the cluster enlargement (REORGANIZE TABLE). Meaning, the step causing the problem is the Cluster enlargement to N+X nodes, including REORGANIZE of the fact tables. 

## Prerequisites

1. Database running on N nodes
2. Fact tables have no distribution keys
3. Data is inserted in a mostly sorted way (ie. daily data with daily timestamps)
4. Data is queried using strong date filters

## Explanation

Reorganize is content-agnostic and tries to move as little data as possible. In fact, on each of the N nodes, the data inserted last is taken and transmitted to the X new nodes until data is balanced across all nodes.  
With chronologically sorted data, data inserted last equals the latest data... this means that data will be split across the cluster, with N nodes storing 'old data' and X nodes storing 'new data'.

In the worst case, X==1 and any query asking for the latest data are performed on one node only.

To avoid this, always put a distribution key on your fact tables, but **not** on a date column.

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 