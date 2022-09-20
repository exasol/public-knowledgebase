# DOUBLE values 
## Problem

Working with DOUBLE values sometimes results in inaccuracy.

## Diagnosis

Those inaccuracies are not unexpected when dealing with DOUBLEs. As DOUBLE is an approximative data type, some values can not be stored exactly. This is a general issue of floating-point arithmetic.

You can verify the data type of your column by creating a table using the query and viewing the data types for the newly-created column, for example: 


```"code-java"
CREATE TABLE TEST AS SELECT ROUND(((71222-65504)/65504*100) ,1); -- Creates a DOUBLE
```
## Solution

You can use an exact numeric type, like DECIMAL to remove inaccuracies.  Such as the example below:


```"code-sql"
SELECT ROUND(CAST((71222-65504)/65504*100 AS DECIMAL(16,3)) ,1); > 8.7 SELECT cast(1 as DECIMAL(17,16)) - cast(1E-16 as DECIMAL(17,16)) AS exact; > 0.9999999999999999
```
## Additional References

* [NumericDataTypes](https://docs.exasol.com/sql_references/data_types/datatypedetails.htm#NumericDataTypes "NumericDataTypes")
* [Typeof (Exasol versions 7.1+)](https://docs.exasol.com/sql_references/functions/alphabeticallistfunctions/typeof.htm "Typeof")
