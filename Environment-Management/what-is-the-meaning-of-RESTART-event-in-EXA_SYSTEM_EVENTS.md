# What is the meaning of RESTART event in EXA_SYSTEM_EVENTS

## Question

I see a "RESTART" event in system view EXA_SYSTEM_EVENTS.

What does it mean?

## Answer

According to [Statistical System Tables](https://docs.exasol.com/db/latest/sql_references/system_tables/statistical_system_tables.htm) and [EXA_STATISTICS](https://github.com/exasol/public-knowledgebase/blob/main/Database-Features/exa-statistics.md)
schema EXA_STATISTICS contains historical information about the database.

In particular, system view EXA_SYSTEM_EVENTS (see also [EXA_SYSTEM_EVENTS](https://docs.exasol.com/db/latest/sql_references/system_tables/statistical/exa_system_events.htm) in the docs) records important events on DB level: startup,
shutdown, backup started, backup finished etc.
One of possible event types is "RESTART" with definition "Restart of the DBMS due to a failure".

It is important to note, that the "RESTART" event is artificial, in database logic there are always a SHUTDOWN and a STARTUP step.

"RESTART" event is added to EXA_SYSTEM_EVENTS if the database starts and the most recent event in EXA_SYSTEM_EVENTS is not "SHUTDOWN".
In that case the database thinks that it wasn't stopped normally and inserts a "RESTART" event with MEASURE_TIME equal to the timestamp of the last record in one of internal system tables that is populated approximately every 30 seconds.

The logic behind this process: such a timestamp is approximately the last moment when DB worked normally, then something unexpected happened to one of the internal server components, typically leading to a DB crash and automatic startup a few minutes later.

Nevertheless, in case Log Server (see [The Exasol Logserver](https://github.com/exasol/public-knowledgebase/blob/main/Database-Features/the-exasol-logserver.md)) process hangs or deadlocks, MEASURE_TIME for the "RESTART" event might be unexpected, as it shows the time when the problem started, not the time when the database was eventually stopped and started.

Based on information above, a "RESTART" entry in EXA_SYSTEM_EVENTS often means a crash of one of internal server processes. As a result, it needs to be analyzed by Exasol Support. Server Processes logs, COS logs and coredumps are usually sufficient for the analysis.
They could be pulled using the following command (adapt date arguments for `-s` and `-t`, and DB name for `-e` accordingly):

```shell
exasupport -d 1,2 -s 2022-08-11 -t 2022-08-11 -e MY_DATABASE_NAME -x 3
```

For more details on pulling the logs from Exasol please refer to [Log Files for Support](https://docs.exasol.com/db/latest/administration/on-premise/support.htm).

## Additional References

* [EXA_SYSTEM_EVENTS](https://docs.exasol.com/db/latest/sql_references/system_tables/statistical/exa_system_events.htm)
* [Statistical System Tables](https://docs.exasol.com/db/latest/sql_references/system_tables/statistical_system_tables.htm)
* [EXA_STATISTICS](https://github.com/exasol/public-knowledgebase/blob/main/Database-Features/exa-statistics.md)
* [The Exasol Logserver](https://github.com/exasol/public-knowledgebase/blob/main/Database-Features/the-exasol-logserver.md)
* [Log Files for Support](https://docs.exasol.com/db/latest/administration/on-premise/support.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
