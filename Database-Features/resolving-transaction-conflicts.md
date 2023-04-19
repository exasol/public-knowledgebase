# Resolving Transaction Conflicts 
## Problem

Transaction Conflicts primarily occur due to Exasol's serializable transaction isolation level. These situations are described in detail in the links found in [Additional References](#h_860657361604480806672):

In the scenarios described above, different queries might fall into a WAIT FOR COMMIT and have to wait for another session to commit changes before the query can begin processing (including SELECT statements). This article will describe how to resolve these conflicts and investigate them. 

## Diagnosis

A user may identify this problem by complaining that the query is running slow. In cases of very simple queries on tables which normally run very fast, a user may notice that the query takes significantly longer or is "stuck" and never completes. 

**If the query is still running:**

You can immediately diagnose if this is the case by looking into the EXA_DBA_SESSIONS or EXA_ALL_SESSIONS. For each session which experiences a WAIT FOR COMMIT, you will see that the session has the activity "Waiting for session &lt;Session ID&gt;". The session mentioned in the ACTIVITY column is known as the "Conflict Session ID".


```markup
SELECT * FROM EXA_ALL_SESSIONS WHERE INSTR(ACTIVITY,'Waiting') > 0;
```
**If the query was in the past:**

You can view previous transaction conflicts by viewing the table EXA_DBA_TRANSACTION_CONFLICTS, which contains a historicized record of every transaction conflict. You can filter the table by the affected session ID to determine if the session in the past experienced a transaction conflict while the query was running:


```markup
SELECT * FROM EXA_DBA_TRANSACTION_CONFLICTS WHERE SESSION_ID = <Session ID>;
```
## Explanation/Investigation

In many cases, it is worth it to investigate the exact cause of the conflict in order to better understand the cause and prevent it in the future. For WAIT FOR COMMIT on write/write scenarios (meaning two sessions writing to the same table at the same time), the only involved sessions are the SESSION_ID and CONFLICT_SESSION_ID found in EXA_DBA_TRANSACTION_CONFLICTS. Therefore, no other work is needed to investigate the exact cause of these conflicts.

For [complex read/write scenarios](https://exasol.my.site.com/s/article/Transaction-Conflicts-for-Mixed-Read-Write-Transactions), it is much more complicated to investigate and is only possible by using [Auditing](https://docs.exasol.com/database_concepts/auditing.htm) or analyzing the [database logs](https://docs.exasol.com/administration/on-premise/support/logs_files_for_sql_server_processes.htm) (via Exasol Support). To investigate transaction conflicts using auditing, you can view [this article](https://exasol.my.site.com/s/article/Investigating-Transaction-Conflicts-using-Auditing).

## Recommendation

When a transaction conflict occurs, there are only two options to resolve the problem:

**1. Kill the offending Session**

The session that needs to be killed is the one that is found in the "Waiting for " message in EXA_ALL_SESSIONS. Additionally, this is stored as the CONFLICT_SESSION_ID in EXA_DBA_TRANSACTION_CONFLICTS . The session can be killed with the following statement:


```markup
KILL SESSION <Conflict Session ID>;
```
**2. Wait for the commit**

The other option is to take no action, and simply let the conflict session ID commit. If you know for sure that the conflict session ID is in the middle of a job or will complete very soon, then it might be appropriate to let the conflict persist until the conflict session ID has the time to commit. You can monitor the progress of this session also in the EXA_ALL_SESSIONS/EXA_DBA_SESSIONS table.


```markup
SELECT * FROM EXA_DBA_SESSIONS WHERE SESSION_ID = <conflict session Id>;
```
If the conflict session is simply left open (STATUS='IDLE') and not doing anything, waiting for the session may not be an option and may need to be killed. 

In general, you can use the query found in [this article](https://exasol.my.site.com/s/article/How-to-determine-idle-sessions-with-open-transactions-Except-Snapshot-Executions) to determine which sessions are idle and have open transactions. 

Exasol recommends to keep autocommit on and not leave transactions open for too long. 

## Additional References

* <https://docs.exasol.com/database_concepts/transaction_management.htm>
* <https://exasol.my.site.com/s/article/Transaction-System>
* <https://exasol.my.site.com/s/article/Filter-on-system-tables-and-transaction-conflicts>
* <https://exasol.my.site.com/s/article/Transaction-Conflicts-for-Mixed-Read-Write-Transactions>
* <https://exasol.my.site.com/s/article/How-to-determine-idle-sessions-with-open-transactions-Except-Snapshot-Executions>
* <https://exasol.my.site.com/s/article/Investigating-Transaction-Conflicts-using-Auditing>
