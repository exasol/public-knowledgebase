# ROWNUM cannot be used in combination with this statement. 
## Problem

## EXASolution's ROWNUM is not compatible with Oracle's ROWNUM!

While ROWNUM in Oracle can be used to limit output data of almost arbitrary statements, EXASolution implements ROWNUM while sticking to the overall SQL semantics: Anything you put into the WHERE clause of a statement filters**input data**. To avoid confusion and seemingly wrong results, we only allow ROWNUM in situations where the result is in line with Oracle's semantic.

## Diagnosis

## Example to clarify:

Assumed there's a table "customer" containing a large number of "Schmitts".


```"code-sql"
select * from customer where c_name like 'Schmitt%'; -- works, but too many rows  select * from customer where rownum < 11; -- works, only ten rows, but no "Schmitt's"  select *       from customer    where c_name like 'Schmitt%'        and rownum < 11; -- Error, ROWNUM can't be combined with other conditions in where clause 
```
In the last statement, Oracle would first filter for all the Schmitts and only output the first 10 matches. Using strict SQL semantics, the filters on c_name and ROWNUM would be independent, meaning that only Schmitts appearing in the first 10 rows of the table get returned.  
As this is probably not what you expect (coming from Oracle), we prevent this statement:**ROWNUM has to be the only one condition in the where clause**

## Solution

The follwoing SQL depicts a Workaround / Solution:


```"code-sql"
-- use a subselect select *     from (select *             from customer           where c_name like 'Schmitt%')   where rownum < 11; -- works, ten rows with "Schmitt's"  -- use LIMIT instead of ROWNUM select *     from customer     where c_name like 'Schmitt%'     LIMIT 10; 
```
Additionally, there are some statements which generally don't allow the  
usage of ROWNUM


```"code-sql"
select c_name with invalid primary key (c_custkey)       from customer  where rownum < 11; -- Error, ROWNUM cannot be used in combination with this statement
```
