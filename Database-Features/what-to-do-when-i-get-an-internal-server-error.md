# What to do, when I get an Internal Server Error 
## Scope

When executing a query, you might receive an internal server error. This article will show you what information you need to investigate it.

## Diagnosis

An Internal Server error has occurred if you receive one of the following error messages:


```
[40005] Successfully reconnected after internal server error, transaction was rolled back.
```

```
[42000] Internal server error. Please report this. Transaction has been rolled back. 
```
## Explanation

It is difficult to determine the exact cause of Internal Server Errors without looking into the logs. The exact cause of the internal server error could be something that is reproducible or not. Since the error message does not state the exact problem, you can try various things to remove the error message, for example:

* Re-writing the query
* Restarting the database
* Re-creating affected objects

These can all be difficult to perform, however, so the best course of action is to prepare logs for Exasol support to investigate. 

## Recommendation

To further investigate the cause, please open a support ticket and include the following information:

* Session ID that got the error
* SQL text of that session ID
* If the error is reproducible or not? If so, how?
* DDL of the tables and views used in the query so that we can reproduce it.
* [SQL/Server Logs for the day that it happened](https://docs.exasol.com/administration/on-premise/support/logs_files_for_sql_server_processes.htm)

Once we have investigated, we will let you know of any potential workarounds and fixes.

## Additional References

* [Gathering Logs for Support](https://docs.exasol.com/db/latest/administration/on-premise/support.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 