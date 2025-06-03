# Query to find out who created a particular schema

## Problem

How to know who created a particular schema and when it was last used.

## Solution

To find out who a created particular schema,one can evaluate sql_text from exa_dba_audit_sql table.

Below is the query.

```sql
SELECT  ses.user_name,
        aud.start_time,
        sql_text
FROM exa_dba_audit_sql aud
JOIN exa_dba_audit_sessions ses
      on aud.session_id=ses.session_id
      where command_name ='CREATE SCHEMA'
      and aud.success=true
```  

Unfortunately,it is not very feasible to find out when the schema was last accessed as there might be references within the views and lack of history of those views.

Note : The MIGRATION schemas are typicaly created by Exasol employees for database migrations (hardware change or v7 -> v8). This is done in maintenance mode where system tables, including auditing are not maintained so above query will not list these schemas.
       Also, audit can be disabled or truncated by a particular SQL command, so exa_dba_audit_sql doesn't have to contain the full history of statement execution.
