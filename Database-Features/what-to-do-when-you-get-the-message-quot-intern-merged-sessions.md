# What to do, when you get the message &quot;Intern Merged Sessions&quot; 
## Scope

Intern merged sessions is due to a performance optimization where some transactions may get merged internally into some kind of super transaction in order to minimize the memory footprint of the server processes (object server).   
This article will describe what you can do when you see the note "intern merged sessions". 

## Diagnosis

A query fails with the below error:


```
GlobalTransactionRollback msg: Transaction collision: automatic transaction rollback (Session: S1)
```
When you check the conflict in EXA_DBA_TRANSACTION_CONFLICTS, it shows the conflict as "**intern merged sessions**" like  in depicted in the following scenario:



| **SESSION_ID** | **CONFLICT_SESSION_ID** | **START_TIME** | **STOP_TIME** | **CONFLICT_TYPE** | **CONFLICT_OBJECTS** | **CONFLICT_INFO** |
| --- | --- | --- | --- | --- | --- | --- |
| **S1** | (null) | T4 | T4 | TRANSACTION ROLLBACK | TEST.T1 | **intern merged sessions** |

## Explanation

 **Intern merged session** could occur in the following scenario:

| **Time** | **Session S1** | **Session S2** | **Note** |
|---|---|---|---|
|T1   |```@set autocommit off;```<br />```CREATE OR REPLACE TABLE TEST.T2 LIKE TEST.T1;```   |   |read locks table TEST.T1   |
|T2   |   |```INSERT INTO TEST.T1 SELECT * FROM TEST.T3;```   |write locks TEST.T1   |
|T3   |   |```/* EXAConnection.commit() */ commit;```   |   |
|T4   |```INSERT INTO TEST.T1 values(1);```   |   |attempts to write lock table TEST.T1 which causes transaction conflict   |

Whenever two transactions are merged, the resulting "super-transaction" has all the object locks of the composing transactions (read and write locks). While this improves performance and memory footprint, we lose the ability to identify single sessions for conflicts. This is indicated by the 'intern merged sessions' conflict info.  
We use a heuristic to merged active transactions (that may be involved in potential conflicts).

## Recommendation

Once you know the conflict, the focus should be on avoiding the conflict by adapting the loading processes. You can learn more about preventing transaction conflicts in mixed read/write scenarios [here](https://exasol.my.site.com/s/article/Transaction-Conflicts-for-Mixed-Read-Write-Transactions). It includes an explanation into the transaction system as well as some tips and tricks to avoid transaction conflicts.

Locking tables used in a transaction at the beginning of the transaction is a good approach to prevent unwanted transaction rollbacks. 
To lock Tables Required for Transactions in Advance you can use:


```sql
DELETE FROM <table> WHERE FALSE;
```
Example:

```sql
DELETE FROM TEST.T1 WHERE FALSE;
```
If it is not possible to determine the exact conflict from system tables when the transaction is merged, if it happens regularly, if the best practices on avoiding transaction conflicts do not help and if you need further clarity on the exact conflict, [contact Exasol support](https://www.exasol.com/product-overview/customer-support/) and send the [session and server logs](https://docs.exasol.com/administration/on-premise/support/logs_files_for_sql_server_processes.htm) for the day that the conflict occurred. 

## Additional References

* [Investigating Transaction Conflicts using Auditing](https://exasol.my.site.com/s/article/Investigating-Transaction-Conflicts-using-Auditing)
* [Gathering Logs for SQL/Server Processes](https://docs.exasol.com/administration/on-premise/support/logs_files_for_sql_server_processes.htm)
* [Transaction Conflicts in Mixed Read/Write Scenarios](https://exasol.my.site.com/s/article/Transaction-Conflicts-for-Mixed-Read-Write-Transactions)
* [Exasol's Transaction Management System](https://docs.exasol.com/database_concepts/transaction_management.htm)
