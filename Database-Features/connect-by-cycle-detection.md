# CONNECT BY Cycle Detection 
## Problem

As documented (see <https://docs.exasol.com/sql/select.htm>) the connect by cycle detection works different than Oracles implementation. We recommend to change your logic accordingly, however if you want to reduce Exasol results so that they match the Oracle results you can do this using this guide.

## Diagnosis

### Example for cycle detection

Here is a small example to explain the difference between Exasol and Oracle. Given this table: 


```"code-sql"
insert into employees values ('B', 1, 2);
insert into employees values ('E', 3, 4);
insert into employees values ('C', 4, 2);
insert into employees values ('C', 4, 5);
insert into employees values ('A', 2, 99);
insert into employees values ('A', 2, 3);
insert into employees values ('D', 100, 1);
insert into employees values ('F', 99, NULL);
```
You want to get the chain of command for Peters manager. Peter is directly managed by a 3rd line manager who is beneath the CEO. However in this company the 3rd line manager is also managed by the 1st line manager, which generates a cycle.  
When you run this query in Exasol you get the following result:


```"code-sql"
SELECT sys_connect_by_path(name,'-') MANAGER_PATH, 
CONNECT_BY_ISCYCLE ISCYCLE, 
CONNECT_BY_ISLEAF ISLEAF, 
level l
from employees start with manages=99 connect by nocycle prior id = manages 
ORDER BY level;
```


| MANAGER_PATH | ISCYCLE | ISLEAF | L |
| --- | --- | --- | --- |
| -A | 0 | 0 | 1 |
| -A-B | 0 | 0 | 2 |
| -**A-C** | 0 | 0 | 2 |
| -A-B-D | 0 | 1 | 3 |
| -A-C-E | 0 | 0 | 3 |
| -A-C-E-A | 0 | 0 | 4 |
| -A-C-E-A-B | 0 | 0 | 5 |
| -A-C-E-**A-C** | 1 | 1 | 5 |
| -A-C-E-A-B-D | 0 | 1 | 6 |

The reason is that Exasol detects cycles in the current row.  
As the row with id 1 appears the second time in the path, the cycle is detected, see path .A-C-E-A-C

Oracle does not detect rows in the current row, but checks if the child row has a cycle.  
For the same query the result is:



| MANAGER_PATH | ISCYCLE | ISLEAF | L |
| --- | --- | --- | --- |
| -A | 0 | 0 | 1 |
| -A-B | 0 | 0 | 2 |
| -A-C | 0 | 0 | 2 |
| -A-B-D | 0 | 1 | 3 |
| -A-C-E | 0 | 0 | 3 |

The cycle is detected in row .5.1.3, because row 3 has a child (row 4) which has a child that is also an ancestor (row 1). This is kind of a double look ahead.

## Solution

**This Solution describes: how to emulate Oracles behaviour in Exasol**  
If you want the same behaviour in Exasol you have to backtrack two levels from the cycle and remove everything that is a child of the row that oracle marks as cycle.  
For doing this you can use the following pattern. Your query has these parts:


```
SELECT <original SELECT list> 
FROM <original TABLE OR VIEW/subselect> 
<original CONNECT BY clause> 
<original ORDER BY clause> 
```
Apply this pattern:


```"code-sql"
WITH base_table AS (
  SELECT ROW_NUMBER() OVER(ORDER BY rowid) AS row_num, 
  <original SELECT list>
  FROM <original TABLE OR VIEW/subselect>
), add_cols_for_cycle_detection AS (
  SELECT <original SELECT list>
  --extra columns oracle like cycle detection
  sys_connect_by_path(row_num,'.') AS cd_scbp,
  row_num,
  PRIOR row_num cd_prior_row_num,
  CONNECT_BY_ISCYCLE AS cd_cycle
  from base_table 
  <original CONNECT BY clause>
), parent_of_cycle AS (
  SELECT cd_prior_row_num 
  FROM add_cols_for_cycle_detection 
  WHERE cd_cycle=1
), ora_cycle_start AS (
  SELECT cd_scbp, cd_prior_row_num 
  FROM add_cols_for_cycle_detection 
  WHERE row_num IN (SELECT cd_prior_row_num FROM parent_of_cycle)
), ora_like_cb AS (
  SELECT * FROM add_cols_for_cycle_detection 
  WHERE NOT EXISTS(
    SELECT 1 FROM ora_cycle_start 
    WHERE cd_scbp=SUBSTRING(add_cols_for_cycle_detection.cd_scbp,0,len(cd_scbp))
  )
)
SELECT <original SELECT list>
FROM ora_like_cb
<original ORDER BY clause>;
```
Applied to our example query the resulting query is:


```"code-sql"
WITH base_table AS (
  SELECT ROW_NUMBER() OVER(ORDER BY rowid) AS row_num, name, id, manages
  FROM employees
), add_cols_for_cycle_detection AS (
  SELECT sys_connect_by_path(name,'-') MANAGER_PATH, CONNECT_BY_ISCYCLE ISCYCLE, CONNECT_BY_ISLEAF ISLEAF, LEVEL l,
  --extra columns oracle like cycle detection
  sys_connect_by_path(row_num,'.') AS cd_scbp,
  row_num,
  PRIOR row_num cd_prior_row_num,
  CONNECT_BY_ISCYCLE AS cd_cycle
  from base_table start with manages=99 connect by nocycle prior id = manages
), parent_of_cycle AS (
  SELECT cd_prior_row_num 
  FROM add_cols_for_cycle_detection 
  WHERE cd_cycle=1
), ora_cycle_start AS (
  SELECT cd_scbp, cd_prior_row_num 
  FROM add_cols_for_cycle_detection 
  WHERE row_num IN (SELECT cd_prior_row_num FROM parent_of_cycle)
), ora_like_cb AS (
  SELECT * FROM add_cols_for_cycle_detection 
  WHERE NOT EXISTS(
    SELECT 1 FROM ora_cycle_start 
    WHERE cd_scbp=SUBSTRING(add_cols_for_cycle_detection.cd_scbp,0,len(cd_scbp))
  )
)
SELECT MANAGER_PATH, ISCYCLE, ISLEAF, L
FROM ora_like_cb
ORDER BY ISLEAF;
```
The result is the same as in Oracle:



| MANAGER_PATH | ISCYCLE | ISLEAF | L |
| --- | --- | --- | --- |
| -A | 0 | 0 | 1 |
| -A-B | 0 | 0 | 2 |
| -A-C | 0 | 0 | 2 |
| -A-C-E | 0 | 0 | 3 |
| -A-B-D | 0 | 1 | 3 |

If you also want CONNECT_BY_ISCYLE to work like in Oracle, you have to extend the pattern by another CTE ora_cycle:


```"code-sql"
WITH base_table AS (
  SELECT ROW_NUMBER() OVER(ORDER BY rowid) AS row_num, name, id, manages
  FROM employees
), add_cols_for_cycle_detection AS (
  SELECT sys_connect_by_path(name,'-') MANAGER_PATH, CONNECT_BY_ISCYCLE ISCYCLE, CONNECT_BY_ISLEAF ISLEAF, LEVEL l,
  --extra columns oracle like cycle detection
  sys_connect_by_path(row_num,'.') AS cd_scbp,
  row_num,
  PRIOR row_num cd_prior_row_num,
  CONNECT_BY_ISCYCLE AS cd_cycle
  from base_table start with manages=99 connect by nocycle prior id = manages
), parent_of_cycle AS (
  SELECT cd_prior_row_num 
  FROM add_cols_for_cycle_detection 
  WHERE cd_cycle=1
), ora_cycle_start AS (
  SELECT cd_scbp, cd_prior_row_num 
  FROM add_cols_for_cycle_detection 
  WHERE row_num IN (SELECT cd_prior_row_num FROM parent_of_cycle)
), ora_like_cb AS (
  SELECT * FROM add_cols_for_cycle_detection 
  WHERE NOT EXISTS(
    SELECT 1 FROM ora_cycle_start 
    WHERE cd_scbp=SUBSTRING(add_cols_for_cycle_detection.cd_scbp,0,len(cd_scbp))
  )
),  ora_cycle AS (
  SELECT ora_like_cb.*, decode(ora_cycle_start.cd_prior_row_num, NULL, 0, 1) AS cyc 
  FROM ora_like_cb LEFT JOIN ora_cycle_start ON ora_like_cb.row_num=ora_cycle_start.cd_prior_row_num
)
SELECT MANAGER_PATH, ISCYCLE, ISLEAF, l, cyc
FROM ora_cycle;
```
Result:



| MANAGER_PATH | ISCYCLE | ISLEAF | L | CYC |
| --- | --- | --- | --- | --- |
| -A | 0 | 0 | 1 | 0 |
| -A-B | 0 | 0 | 2 | 0 |
| -A-C | 0 | 0 | 2 | 0 |
| -A-B-D | 0 | 1 | 3 | 0 |
| -A-C-E | 0 | 0 | 3 | 1 |

