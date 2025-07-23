# Duration in EXA_DBA_SESSIONS

## Problem

I would like to find current statements that run longer than 600 seconds.

I tried to execute following statement:

```SQL
SELECT * 
FROM EXA_DBA_SESSIONS a
WHERE DURATION > 600;
```

and got the follwoing error message:

```text
[Code: 0, SQL State: 22018]  data exception - invalid character value 
for cast; Value: '0:00:26' (Session: 1838347472240771072)
```

## Explanation

Documentation of [EXA_DBA_SESSIONS](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_dba_sessions.htm) duration column is wrong, describing it as "duration in seconds".

Format is 'HH:MM:SS', with HH not limited to 24 hours.

## Solution

### Solution 1

Exasol SQL dialect doesn't have a direct function, thus we have to parse the string and calculate it:

#### SQL-Query 1

```SQL
SELECT
    SESSION_ID,
    duration,
    -- test
    regexp_substr(duration, '[0-9]+', 1, 1) AS HH,
    regexp_substr(duration, '[0-9]+', 1, 2) AS MM,
    regexp_substr(duration, '[0-9]+', 1, 3) AS SS,
    -- formula
    3600 * regexp_substr(duration, '[0-9]+', 1, 1) -- HH
    + 60 * regexp_substr(duration, '[0-9]+', 1, 2) -- MM
    + regexp_substr(duration, '[0-9]+', 1, 3) -- SS
    AS duration_seconds
FROM 
    exa_dba_sessions 
WHERE 
    local.duration_seconds > 600;
```

#### Output

|SESSION_ID|DURATION|HH|MM|SS|DURATION_SECONDS|
|---|---|---|---|---|---|
|1838347468804849664|4:31:55|4|31|55|16315.0|

### Solution 2

Alternatively, you can convert the 600 seconds to 10 minutes ('0:10:00') and write the query as follows, given that

* minutes and seconds are zero-prefixed and can therefore be sorted alphabetically
* hours are not zero-prefixed, so any number bigger than '0' will also be alphabetically greater.

#### SQL-Query 2

```SQL
SELECT  
s.*
FROM
    EXA_DBA_SESSIONS s
WHERE 
    COMMAND_NAME in ('COMMIT','ROLLBACK')
AND DURATION > '0:10:00'
;
```

## References

* Documentation of [EXA_DBA_SESSIONS](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_dba_sessions.htm)
* Documentation of [EXA_ALL_SESSIONS](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_all_sessions.htm)
* Documentation of [EXA_USER_SESSIONS](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_user_sessions.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
