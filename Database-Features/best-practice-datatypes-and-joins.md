# Best practice: Datatypes and Joins 
## Background

* Joins between tables use up an unexpected amount of time and/or ressources
* Data is missing / not fitered correctly
* We need to use cumbersome expressions for filtering or joining

All this may be caused by a lack of discipline in database design and/or data cleansing.

## Explanation

Since expression indexes (see <https://exasol.my.site.com/s/article/Indexes>) may occur when joining on different datatypes or joining on expressions we recommend having the same data types and homogenous data in the tables that are joined.

Let's assume we have two tables (T1 and T2) with two columns each (ID and COUNTRY_CODE). The COUNTRY_CODE is stored heterogeneous (e.g. 'USA' and 'usa' as COUNTRY_CODE for the United States of America).

The natural way to join both tables is:


```"code-sql"
select count(*)  from t1 join t2   on t1.country_code = t2.country_code; 
```
This will cause Exasol to create an index on one COUNTRY_CODE column. This index will be stored persistently and is maintained and reused for further joins.

But this approach does not return all results since for instance 'usa' and 'USA' don't match.

Therefore it is necessary to change the join condition. E.g.:


```"code-sql"
select count(*)  from t1 join t2   on lower(t1.country_code) = lower(t2.country_code); 
```
This query will cause Exasol to create an expression index on one COUNTRY_CODE column. The expression index will not be stored persistent, it is dropped after query execution.

Assuming that the index creation takes 2s and all other parts of the query 2s in total, the second query (with expression index) will take 4s every time it is executed.  
The first query (with persistent index) will take 4s on first execution, afterward, it will be finished in 2s.

In addition, joining on expressions can negatively affect the accuracy of estimations made by Exasol's query optimizer (such as count of distinct values), leading to bad decisions regarding the execution plans. Depending on the overall setup and use case, this may cause severe performance issues.

**It is highly recommended to keep datatypes and data within a column strict:**  
When storing a certain type of data (monetary amounts, points in time, attributes, ...) make sure that the same physical storage is used in all places. This includes the choice of data types as well as fixing upper/lower case, abbreviations, etc.

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 