# Migration guide: SQL Server/  Azure SQL Database to Exasol 
## Migration Guide

This article adresses some common topics when migrating from SQL Server to Exasol. It focuses on topics that arise when you have already loaded a few tables over. If you haven't already, have a look at [connecting to SQL Server from Exasol](https://docs.exasol.com/loading_data/connect_databases/sql_server.htm "Exasol") and the [database migration script](https://github.com/EXASOL/database-migration#sql-server "Exasol") for yor very first steps of loading data over.


|Topic   |SQL Server   |Exasol   |
|---|---|---|
|Syntax - Schemas   |```USE [my_schema] ```   |```OPEN SCHEMA "my_schema"; ```   |
|Syntax - Quotes   |SQL Server uses square brackets a lot. <br> ```SELECT [my_col] FROM [my_table];```   |Exasol's default way of quoting is with double quotes: <br> ```SELECT "my_col" FROM "my_table";```<br>Quoting with square brackets is also supported, however as double quotes are more Exasol-style, use double quotes if you have the choice.   |
|Common functions   |ISNULL → <br>GETDATE → <br>CHARINDEX →   |COALESCE <br>CURRENT_TIMESTAMP <br>LOCATE   |
|Functions   |There are some SQL Server typical functions like EOMONTH, DATEADD, CONVERT_TO_DATE, PATINDEX, … <br>```SELECT [my_col] FROM [my_table];```   |These functions are not automatically shipped with Exasol, but you can easily add them: Download the functions you need from [EXA_TOOLBOX](https://github.com/exasol/exa-toolbox/tree/master/sqlserver_compatibility "Exasol") and change the function calls in your SQL so that they use the schema-qualified version:<br>```SELECT EXA_TOOLBOX.EOMONTH('2019-02-15');```<br>Or alternatively, create the function EOMONTH from the Toolbox in the schema that you later on want to use it, e.g.:<br>```CREATE OR REPLACE FUNCTION "my_schema".EOMONTH(date_in IN TIMESTAMP)  …```<br>```/```<br>```SELECT EOMONTH('2019-02-15');```    |
|Stored Procedures    |   |   |


|  |  |  |
| --- | --- | --- |
| Topic | SQL Server | Exasol |
| Syntax - Schemas | 
```markup
USE [my_schema]
```
 | 
```markup
OPEN SCHEMA "my_schema";
```
 |
| Syntax - Quotes | SQL Server uses square brackets a lot. 
```markup
SELECT [my_col] FROM [my_table];
```
 | Exasol's default way of quoting is with double quotes: 
```markup
SELECT "my_col" FROM "my_table";
```
  Quoting with square brackets is also supported, however as double quotes are more Exasol-style, use double quotes if you have the choice. |
| Common functions | ISNULL → GETDATE → CHARINDEX → | COALESCE CURRENT_TIMESTAMP LOCATE |
| Functions | There are some SQL Server typical functions like EOMONTH, DATEADD, CONVERT_TO_DATE, PATINDEX, …  
```markup
SELECT EOMONTH('2019-02-15');​
```
 | These functions are not automatically shipped with Exasol, but you can easily add them: Download the functions you need from [EXA_TOOLBOX](https://github.com/exasol/exa-toolbox/tree/master/sqlserver_compatibility "Exasol") and change the function calls in your SQL so that they use the schema-qualified version: 
```markup
SELECT EXA_TOOLBOX.EOMONTH('2019-02-15');​
```
 Or alternatively, create the function EOMONTH from the Toolbox in the schema that you later on want to use it, e.g.: 
```markup
--/ CREATE OR REPLACE FUNCTION "my_schema".EOMONTH(date_in IN TIMESTAMP)  …  /  SELECT EOMONTH('2019-02-15');​
```
 |
| Stored Procedures  | Stored procedures are often used for ETL scripting with multiple steps. Here is a simple example, that performs some normalizations: 
```markup
CREATE procedure [procs].[normalizeGenderData] (  @femaleGenderName VARCHAR(20),  @maleGenderName VARCHAR(20)) as begin   UPDATE Customers SET Gender=@femaleGenderName WHERE (Gender='f' OR Gender='fe');   UPDATE Customers SET Gender=@maleGenderName WHERE (Gender='m' OR Gender='ma'); end GO
```
 | Exasol also a basic set of function, however if you used Stored Procedures in SQL Server, it's recommended to translate them into [Lua Scripts](https://docs.exasol.com/database_concepts/udf_scripts/lua.htm "Exasol") in Exasol.An equivalent Lua Script to the stored procedure example looks like this: 
```markup
--/ CREATE OR REPLACE SCRIPT "procs"."normalizeGenderData"(femaleGenderName, maleGenderName)     RETURNS ROWCOUNT AS        query([[open schema RETAIL]])    rows_updated = 0    res = query([[UPDATE "Customers" SET GENDER=:fgn WHERE (GENDER='f' OR GENDER='fe')]], {fgn=femaleGenderName})    rows_updated = rows_updated + res.rows_updated        res = query([[UPDATE "Customers" SET GENDER=:mgn WHERE (GENDER='m' OR GENDER='ma')]], {mgn=maleGenderName})    rows_updated = rows_updated + res.rows_updated    exit({rows_affected=rows_updated})     / 
```
 |
|  

You have further useful tips for SQL Server to Exasol Migrations? Let us know so that other users can benefit from them too!

