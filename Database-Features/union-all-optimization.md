# UNION ALL optimization 
## Background:

#### As of Version 6.1, Exasol supports partitioning, however, this optimization is still present.

On a typical Exasol cluster, data is **distributed** across multiple nodes very much like a hash partition, but the use case is very different: While partitions are used for filtering (eliminate as many partitions as possible in queries), distribution is used for load balancing (spread the processed data across as many nodes as possible).  
Table data is also split into columns and multiple data blocks per column, such that some features of partitioning are achieved automatically, but this is far from perfect, as blocks may still contain a wide range of rows that should (in some cases) be split into separate partitions.

## Workaround: UNION ALL

Exasol 5 introduced a powerful optimization that can be used for **manual partitioning**:

#### UNION ALL branch elimination using column statistics

As an example, given the following view and statement:


```sql
create view union_all as (
        select * from sales_2011
    UNION ALL
        select * from sales_2012
    UNION ALL
        select * from sales_2013
    UNION ALL
        select * from sales_2014
);

select sum(sales_amount) as turnover
from union_all
where sales_date between date '2013-11-01' and date '2014-02-28';
```
The intent here is that

* Data is stored in separate tables, each containing a densely packed range of data, disjoint from each other. The example uses a date range.
* The database should be able to use this information together with given query filters, removing unneeded objects from the query graph. Thus, further optimizations can be more efficient and less data needs to be processed or loaded to memory.

## Prerequisites:

The mentioned optimization can take place if the **following conditions** are met (as of version 5.0.15):

* All the union branches are simple selects on tables (no expressions, no conditions, no limit, ...)
* All the union branches select all columns from the tables, ****in their original order****. All the tables in the union share the same structure (column order, column types, distribution keys)

Example:


```sql
-- slow variant => not all columns included
SELECT *
FROM ( 
  SELECT a FROM T
  UNION ALL
  SELECT a FROM T
) LIMIT 9;

-- fast variant => all columns in original order included
SELECT *
FROM ( 
  SELECT * FROM T
  UNION ALL
  SELECT * T
) LIMIT 9;
```
If those conditions are met, the **following optimization** is possible if the outer select contains a **literal filter** (no subselects, no joins, etc) that can be propagated to a column of the union all view:

* The database will (create and) evaluate column statistics (min/max) for the filtered column
* Based on those values, whole branches are eliminated from the union all
	+ Assuming that the table names are representative in the example above, it will eliminate years 2011 and 2012 from the query graph
* The remaining branches will be placed in a temporary wrapper object for actual query processing
	+ If there is only one branch, the union view will actually be replaced by that single table

Properties of the **union table wrapper**:

* If used as a scan table,
	+ the scan simply iterates through the contained tables
	+ no pre-materialization necessary
* If used as a join table,
	+ Individual indices are (created and) used on the (not eliminated) underlying tables. This may reduce resource requirements when creating new indices on the full union and also memory requirements as only indices of selected tables are accessed.
	+ All index accesses are wrapped to automatically return data from all the contained indices.
	+ No pre-materialization is required

**Limitations** of the union wrapper:

* **Views are read only**, so ETL will have to make sure the right data ends up in the right table.
* The elimination is based on **data ranges**, so it is mostly suitable for monotonous data (creation date, etc) or manually grouped data. It is unsuitable for strings (hashes) or other non-contiguous data.
* As access to wrapped indices adds overhead (asking 10+ indices for data when only one may return results), the implementation is (per default) limited to **128** branch tables
* As the branches have to select from actual tables, cascading is not possible.
* One single outlier in data (NULL, -inf, +inf) may 'corrupt' column statistics and prevent branches from being eliminated

## Usage indications

### For UNION ALL:

* **Single fact table with date/timestamp column:**  
Typically all reports will query only a small time slice using hard date literals as filters. This will lead to strong table elimination in the union wrapper.
* **Really big tables:**  
Even when query structure will not allow any union optimizations, the underlying mechanics might prove useful:
	+ Indices are built on tables, not on the union. Overall index build time will not decrease, but peak memory consumption will be drastically reduced. Also in case of table updates, only one of the tables is affected per statement.
	+ Enforced data locality and possible boost for later pipeline stages
* **Parallel write of small to medium tables:**  
If you have multiple streams that need to write into a common table, this may be simulated by providing a table for each stream and combining them through a union wrapper. This avoids transaction conflicts between the writing processes but typically will provide no segmentation information for table elimination in queries. This concept can be extended to a single fact table with a set of assorted 'tail segments' that are consolidated by some ETL process.

### Against UNION ALL:

* **Multiple fact tables:**  
Typically, fact tables are not joined together through date columns, and (almost) no application will put timeslice filters on multiple tables in a query. This means that at most one of the fact tables can be wrapped successfully. If you try to wrap both/all of them, you will probably incur penalties for union-wrapped index lookups.
* **Indirect partitioning:**  
When the fact table does not contain the partitioning information (date) directly, but only as a foreign key based on some dimension, for example dim_calendar. Any date filter in queries will be put on the dimension table and will not be available for union optimization. Minor advantages might arise from data locality, but typically the index overhead will dominate.

## Additional References

<https://www.exasol.com/support/browse/EXASOL-1362> 

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 