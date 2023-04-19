# How to avoid SQL syntax errors in Exasol by enabling Unified Quoting in MicroStrategy 
## Background

In rare cases it can happen that you might receive SQL errors like the following examples when SQL´s (generated from reports) are pushed down from MicroStrategy to Exasol:

"[EXASOL][EXASolution driver]syntax error, unexpected DATE_, expecting UNION_ or EXCEPT_ or MINUS_ or INTERSECT_ "

"[EXASOL][EXASolution driver]syntax error, unexpected TIMESTAMP_, expecting UNION_ or EXCEPT_ or MINUS_ or INTERSECT_ "

"[EXASOL][EXASolution driver]syntax error, unexpected UPDATE_, expecting UNION_ or EXCEPT_ or MINUS_ or INTERSECT_ "

The root cause for that problem can most likely be found in the structure of your data tables, views or queries. 

**You should generally avoid using so-called "identifiers" ([SQL reserved words](https://docs.exasol.com/sql_references/metadata/metadata_system_tables.htm#EXA_SQL_KEYWORDS))** **as column names (e.g. DATE, TIMESTAMP, UPDATE, BEGIN, END, CHECK, TRUE, FALSE, etc.)** when creating your tables/views or setting aliases in SQL queries.

But... as we all know, sometimes you cannot avoid this due to given data structures.


```
Example 1  
The following query will fail with the error:  
[EXASOL][EXASolution driver]syntax error, **unexpected DATE_**, expecting UNION_ or EXCEPT_ or MINUS_ or INTERSECT_   
  
SELECT  
a.CUSTOMER_ID CUSTOMER_ID,  
a.CUSTOMER_NAME CUSTOMER_NAME,  
a.DATE DATE  
FROM  
X.CUSTOMER a  
WHERE  
a.CUSTOMER_ID = 1234;  

```
So the query needs to be modified to run without errors. In this case the column and alias, that causes the error (DATE) must be quoted with double quotes as shown in the following example:


```
Example 2
The following query will run without errors:

SELECT
a.CUSTOMER_ID CUSTOMER_ID,
a.CUSTOMER_NAME CUSTOMER_NAME,
a."DATE" "DATE"
FROM
X.CUSTOMER a
WHERE
a.CUSTOMER_ID = 1234;
```
**To solve this issue when pushing down SQL from MicroStrategy to Exasol you must enable "Unified Quoting" in your MicroStrategy environment.**

## Prerequisites

Unifying the quoting behaviour is available since the release of MicroStrategy 2020 and described in the following MicroStrategy Knowledge Base article: **[KB483540](https://community.microstrategy.com/s/article/KB483540-Unified-Quoting-Behavior-for-Warehouse-Identifiers?language=en_US)**

To implement the behaviour also for database connections to Exasol, the following steps need to be done with the release of MicroStrategy 2020. **MicroStrategy 2021 supports the unified quoting for Exasol out of the box and no further configurations are needed.**

## How to enable Unified Quoting in MicroStrategy 2020 for Exasol

## Step 1

**Ensure that all of your projects are migrated to MicroStrategy 2020** when upgrading from a previous MicroStrategy version, see MicroStrategy Knowledge Base article **[KB483540](https://community.microstrategy.com/s/article/KB483540-Unified-Quoting-Behavior-for-Warehouse-Identifiers?language=en_US)**

* **Upgrade the Data Engine Version**
* **Upgrade the Metadata**

## Step 2

**Install the new database object "new_database_m2021.pds"** as described in chapter 3 of the MicroStrategy Knowledge Base article **[Exasol 6.x](https://community.microstrategy.com/s/article/Exasol-6-x?language=en_US)**

**Be sure to change all of your existing Exasol Database Connections in MicroStrategy to the newly installed database object (Database Connection Type)** **"EXAsolution 6.x"** and check all connection parameters accordingly as described in the [Exasol Documentation](https://docs.exasol.com/connect_exasol/bi_tools/microstrategy/microstrategyintelligenceserver.htm)

All relevant steps are described in MicroStrategy Knowledge Base article [KB43537](https://community.microstrategy.com/s/article/KB43537-How-to-install-DBMS-objects-provided-by-MicroStrategy?language=en_US)

**The following steps 3 and 4 are only needed if you set up the connection to Exasol for the first time or your Exasol Database Version has changed:**

## Step 3

**Download the latest Exasol JDBC driver**(or ODBC driver) from the Exasol Download section **[V7.0](https://www.exasol.com/portal/display/DOWNLOAD/7.0)** or **[V6.2](https://www.exasol.com/portal/display/DOWNLOAD/6.2)** (according to your database version)

## Step 4

**Install the latest Exasol JDBC driver** (or ODBC driver) **on each MicroStrategy Intelligence Server in the cluster** as described in chapter 4 of the MicroStrategy Knowledge Base article **[Exasol 6.x](https://community.microstrategy.com/s/article/Exasol-6-x?language=en_US)**. **Do not forget to restart the Intelligence Server** after installing the driver. You might also follow chapter 5 and 6 in the KB article.

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 