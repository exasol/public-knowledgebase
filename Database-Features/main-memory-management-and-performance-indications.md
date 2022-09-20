# Main Memory Management and Performance Indications 
## Background

You always get the highest performance if the data to be analyzed fits into main memory available to the database (your license).

## Explanation

EXASolution stores data column-wise both in memory and on disk. Each column is spread across a number of physical blocks and of course across the nodes. Only blocks, required to compute the query, will be loaded into main memory.

Indexes will be treated in the same way: indexes are physically stored in blocks and only the needed blocks will be loaded into main memory. Please refer to [indexes](https://community.exasol.com/t5/database-features/indexes/ta-p/1512)for more details on indexes.

Typically, there's no need to hold the full set of data in memory. EXASolution loads the data requested by queries into main memory on demand (so called hot data) and swapps them out if needed. EXASolution monitors the memory consumption and provides you with a suggestion for the optimum sizing (RECOMMENDED_DB_RAM_SIZE_*).

If you persistently observe, that "RECOMMENDED_DB_RAM_SIZE_AVG" is at least 30 to 50% higher than your license and you experience performance issues, it means you would need to take an increase of DBRAM into consideration. On the other hand, a deeper system analysis could help to identify queries causing high memory consumption. There are a number of ways for improving the performance and for reducing the memory consumption in EXASolution.

In general, upgrading hardware/RAM or license should be bottleneck driven. To increase performance or it has measurably deterred over time, than we suggest to investigate the bottleneck and work on this by

* identifying critical queries and optimize them
* adding more nodes if your system is CPU bound
* adding more disks/nodes if the space runs out anyway
* adding a better network if your system is network bound
* increasing DBRAM if your system has lots of HDD_READ

## Additional References

Please consider

* becoming an EXASOL Certified Performance Expert by attending our Performance Training: see["Exasol Performance Management" course on Exacademy](https://exacademy.exasol.com/courses/course-v1:Exasol+PERF+X/about)
* Index creation: [Indexes](https://community.exasol.com/t5/database-features/indexes/ta-p/1512)
