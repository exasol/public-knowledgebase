# Connection lost after session running out of memory 
## Scope

The error we are addressing is connection lost after the session runs out of memory. It was encountered while running a Lua script on Exasol version 6.2.11. Just so you are aware, the DBRAM is currently split in two parts: Heap (showing as MEM in profiling) and other (for keeping data blocks). This article looks at both potential errors: 1. SESSION out of memory; 2. SYSTEM out of memory. 

## Diagnosis

Before going into detail, please review [CHANGELOG: Queries containing a very high number of JOINs may fail](https://exasol.my.site.com/s/article/Changelog-content-11113?language=en_US) that addresses one of the reasons you may receive the error: 

```
Connection lost after session running out of memory
```

If you are experiencing session out of memory running joins with the USING clause (versus joins with the ON clause), be aware that joins with the USING clause have higher resource consumption and processing efforts than the join with the ON clause. Changing your join USING to join ON can reduce the query's claim on total resources and can prevent the session from running out of heap memory. 

The above information and much more are covered on our best practices page: [Best Practices](https://docs.exasol.com/performance/best_practices.htm).

Continuing on, there are two heap parameters controlling memory usage: **maxProcessHeapMemory** and **maxSystemHeapMemory.**

## Explanation

In Exasol all SQL session and database management processes share a default system heap memory of 32 GiB, which is part of DBRAM. If this limit is reached, the topmost consuming sessions are terminated and deliver the error message "SYSTEM running out of heap memory". At the session-level, the `maxProcessHeapMemory` parameter impacts the session's working memory (doesn't include the cached tables) of the SQL running. A query might fail with a "SESSION out of memory" error:

```
Connection lost after session running out of memory.
```

if it uses more than the specified `maxProcessHeapMemory`.

Database also checks if sum or all sessions' working memory + memory of related UDF and IMPORT/EXPORT processes exceeds the value of `maxSystemHeapMemory` DB parameter. Sessions consuming the most of memory will fail with "SYSTEM out of memory" error:

```
Connection lost after system running out of memory.
```

## Recommendation

**Scenario:**  Exasol sets the session-level heap to 4GiB, which is optimized to keep rouge queries from over-consuming resources needed by other queries. Changing the session-level heap impacts all queries and potentially can impede performance if your workload is waiting on cores and RAM consumed by particular resource-intensive queries. If your use case requires more heap memory, you can change the `maxProcessHeapMemory` parameter which controls the session-level heap allocation. The workaround is to change:


```
-maxProcessHeapMemory=4096
```

to

```
-maxProcessHeapMemory=8192
```

Be aware that changing this parameter means every connection *can* now use up to 8192 MiB. Your allocated resources will determine whether this is an appropriate action to take. You can make this change in a multiple ways:

* In EXAOperation, for deployments having EXAOperation: [Edit a Database](https://docs.exasol.com/db/7.1/administration/on-premise/manage_database/edit_database.htm)
* In commandline via ConfD (`confd_client + db_configure + (params_add OR params_delete OR params)`): [db_configure](https://docs.exasol.com/db/latest/confd/jobs/db_configure.htm)
* Via REST API: [Add Database Parameters](https://docs.exasol.com/db/latest/administration/aws/manage_database/add_db_parameters.htm)

Since version 8.29.0 system heap limit should be changed via option `max_system_heap_memory` of ConfD job [db_configure](https://docs.exasol.com/db/latest/confd/jobs/db_configure.htm). See [CHANGELOG: Improved configuration of database system heap memory](https://exasol.my.site.com/s/article/Changelog-content-17833?language=en_US).

Either way requires a DB restart and, therefore, a short downtime.

**Scenario:**  If the 32 GiB system heap memory limit is reached, the topmost consuming SQL sessions are terminated and deliver the error message "*system* running out of heap memory". The workaround is to increase the `maxSystemHeapMemory`, like this:

```
-maxSystemHeapMemory=65534
```

Changes to this parameters need to be agreed with Exasol Support.

## Additional References

* [CHANGELOG: Queries containing a very high number of JOINs may fail](https://exasol.my.site.com/s/article/Changelog-content-11113?language=en_US)

* [CHANGELOG: Improved system usability in case of heavy load and swapping](https://exasol.my.site.com/s/article/Changelog-content-5000?language=en_US)

* [CHANGELOG: High memory usage when inserting into distributed table with many varchar columns](https://exasol.my.site.com/s/article/Changelog-content-8211?language=en_US)

* [Version 7.1, Edit a Database](https://docs.exasol.com/db/7.1/administration/on-premise/manage_database/edit_database.htm)

* [Version 8, db_configure](https://docs.exasol.com/db/latest/confd/jobs/db_configure.htm)

* [Version 8, Add Database Parameters](https://docs.exasol.com/db/latest/administration/aws/manage_database/add_db_parameters.htm)

* [CHANGELOG: Improved configuration of database system heap memory](https://exasol.my.site.com/s/article/Changelog-content-17833?language=en_US)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 
