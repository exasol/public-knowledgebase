# No-write-operation-allowed-in-snapshot-mode-during-DQL

## Problem

DQL(SELECT) on the system tables in snapshot mode fails with below error 
```
GlobalTransactionRollback msg: No write operation allowed in snapshot mode.
```

## Solution

During the Exasol DB version upgrade, some of the system tables can be altered as a result views depending on them become invalid.
By design, the first time query to an invalid view tries to validate it (write operation).
Snapshot execution mode is a special transaction mode that, in particular, minimizes the amount of transaction conflicts (see [**Snapshot mode**](https://docs.exasol.com/db/latest/database_concepts/snapshot_mode.htm "snapshot") ). However, by definition snapshot execution mode is read-only, so such SELECTs after the system upgrade can fail with mentioned error.



   If the SELECT/DQL is via some application, It will make sense for the application to run
   a SELECT (without snapshot execution mode) against objects depending on Exasol system views that application is using in
   snapshot execution mode after every DB update. If needed, one can do it only for a subset of invalid views, like

```sql
-- Filter on schema name and potentially on object name is to be refined on application side

SELECT
   distinct
   c.COLUMN_OBJECT_TYPE,
   c.column_schema,
   c.column_table
FROM      
   exa_dba_columns c      
WHERE     
1=1
  and c.status in ('OUTDATED')     
  and c.column_schema in ('<application_name>')

UNION ALL

SELECT
distinct
  c.COLUMN_OBJECT_TYPE,
  c.column_schema,
  c.column_table
FROM      
  exa_sys_columns c      
WHERE     
  1=1
  and c.status in ('OUTDATED')     
  and c.column_schema in ('<application_name>')
   
ORDER BY      
1, 2, 3      
;
```   
Another solution is to run
```DESCRIBE <OBJECT SCHEMA>.<OBJECT NAME> ```
for the respective objects.

So, after the system upgrade (on application startup / before DDL (re-)deployment / anything else that makes sense from business logic perspective) , one can do SELECT or DESCRIBE exercise to avoid the error.


#### Additional references:

* [How to find invalid views](https://exasol.my.site.com/s/article/How-to-Find-Invalid-Views?language=en_US#:~:text=Answer,field%20will%20be%20%22OUTDATED%22.)

* [Snapshot mode](https://docs.exasol.com/db/latest/database_concepts/snapshot_mode.htm)




 
 

