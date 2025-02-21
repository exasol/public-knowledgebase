
# How to search Exasols audit tables to see which users had the most SQL queries in a given period

## Problem

We have an unusual peak in our DQL queries and would like to know which user with which IP is responsible for it.

![Peak](images/PeggySchmidtMittenzweiDQLHighPeak2.png)

This diagram visualizes the table [EXA_SQL_HOURLY](https://docs.exasol.com/db/latest/sql_references/system_tables/statistical/exa_dba_audit_sql.htm) for the attribute COMMAND_CLASS with the value DQL.

## Solution

Using the tables 
* [EXA_DBA_AUDIT_SESSIONS:](https://docs.exasol.com/db/latest/sql_references/system_tables/statistical/exa_dba_audit_sessions.htm) The system table stores all the sessions from the moment you enable it and start the database.

* [EXA_DBA_AUDIT_SQL:](https://docs.exasol.com/db/latest/sql_references/system_tables/statistical/exa_dba_audit_sql.htm) The system table stores all executed SQL statements from the moment you enable it and start the database.

we can create the following query 

```sql
SELECT
    TRUNC(START_TIME,'MI') as Minutes
    --TRUNC(START_TIME,'DD') AS Hours,
    , USER_NAME                 
    , OS_USER
    , HOST
    , COUNT(*)
FROM
    EXA_STATISTICS.EXA_DBA_AUDIT_SQL sq
JOIN
    EXA_STATISTICS.EXA_DBA_AUDIT_sessions se
ON
    se.session_id=sq.session_id
WHERE
    1=1
--AND sq.start_time BETWEEN DATE'2025-02-19' AND DATE'2025-02-16'
AND sq.start_time BETWEEN '2025-02-01 07:00:00' and '2025-02-19 08:00:00'
AND COMMAND_CLASS IN ('DQL')
GROUP BY 1, 2, 3, 4
ORDER BY 
    5 DESC 
LIMIT 100;
```

### Example output

| MINUTES | USER_NAME | OS_USER | HOST | COUNT(*) |
| :---:   | :---: | :---: | :---: | :---: |
|2025-02-09 07:20:00|USER_X|OS_X|2.134.213.2|750|
|2025-02-09 07:22:00|USER_X|OS_X|2.134.213.2|300|
|2025-02-09 07:30:00|USER_Y|OS_Y|2.134.213.4|200|
|2025-02-09 07:21:00|USER_X|OS_X|2.134.213.2|50|
|2025-02-09 07:50:00|USER_Z|OS_Z|2.134.217.4|40|

## Additional References

* [Auditing](https://docs.exasol.com/db/latest/database_concepts/auditing.htm)
* [EXA_DBA_AUDIT_SESSIONS](https://docs.exasol.com/db/latest/sql_references/system_tables/statistical/exa_dba_audit_sessions.htm)
* [EXA_DBA_AUDIT_SQL](https://docs.exasol.com/db/latest/sql_references/system_tables/statistical/exa_dba_audit_sql.htm) 


*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 
