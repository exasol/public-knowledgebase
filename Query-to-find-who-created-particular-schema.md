# Query to find who created particular schema

## Problem

How to know who created particular schema and when were they last used.

## Solution

To find out who created particular schema , you can evaluate sql_text from exa_dba_audit_sql table . 

Below is the query 

```sql
SELECT ses.user_name,
       sql_text
FROM exa_dba_audit_sql aud
JOIN exa_dba_audit_sessions ses
ON   aud.session_id=ses.session_id
     WHERE command_name ='CREATE SCHEMA'
     AND aud.error_code <> 1
```  

Unfortunately ,it is not very feasible to find out when the schema was last accessed as there might be references within the views, and lack of history of those views. 

Note : The MIGRATION schemas are typicaly created by Exasol employees for database migrations (hardware change or v7 -> v8).
       This is done in maintenance mode where system tables,including auditing are not maintained so above qury will not list these schemas
