# Duration in EXA_DBA_SESSIONS

## Problem

I would like to receive current statements that run longer than 10 minutes.

I tried to execute following statement:

```SQL
SELECT * 
FROM EXA_DBA_SESSIONS a
WHERE DURATION < 10*60;
```

and got the follwoing error message:

```text
[Code: 0, SQL State: 22018]  data exception - invalid character value 
for cast; Value: '0:00:26' (Session: 1838347472240771072)
```

## Explanation

[EXA_DBA_SESSIONS](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_dba_sessions.htm) is wrong, describing it as "duration in seconds".

Format is 'HH:MM:SS', with HH not limited to 24 hours.

## Solution

Exasol SQL dialect doesn't have a direct function, thus we have to parse the string and calculate it:

```SQL
SELECT  
s.*
FROM
    EXA_DBA_SESSIONS s
WHERE 1=1
  AND COMMAND_NAME in ('COMMIT','ROLLBACK')
  AND CAST(SUBSTRING(duration, 1, INSTR(duration, ':') - 1) AS INT) * 3600 +  -- Hours
      CAST(SUBSTRING(duration, INSTR(duration, ':') + 1, INSTR(duration, ':', 1, 2) - INSTR(duration, ':') - 1) AS INT) * 60 + -- Minutes
      CAST(SUBSTRING(duration, INSTR(duration, ':', 1, 2) + 1) AS INT)        
      > 10*60
;
```

## References

* [EXA_DBA_SESSIONS](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_dba_sessions.htm)
* [EXA_ALL_SESSIONS](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_all_sessions.htm)
* [EXA_USER_SESSIONS](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_user_sessions.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*

