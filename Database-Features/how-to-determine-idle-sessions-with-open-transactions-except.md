# How to determine idle sessions with open transactions (Except Snapshot Executions) 
## Background

Idle sessions with open transactions may have some negative implications:  
First, there might be more transaction conflicts in parallel sessions, most likely if the idle session has an open write transaction.  
Second, the database garbage collection might not be able to reclaim older object versions though increasing storage space usage and backup sizes.

## How to determine idle sessions with open transactions

You can use the following SQL statement to add locking information to your session system tables using the EXA_SQL_LAST_DAY / EXA_DBA_AUDIT_SQL data:

**DISCLAIMER  
An Auto-Commit is not always set for executions in Snapshot-Mode. Thus, in the case of snapshot execution, this solution can lead to false-positive read locks.**

**=> We recommend to use caution when developing watchdog scripts which automatically kill all critical read locks**

For Database versions `up to 7.0` the query can be found in

[open_transactions_leq_DBv70.sql](https://raw.githubusercontent.com/exasol/exa-toolbox/master/utilities/open_transactions_leq_DBv70.sql) 

For Database versions `starting from 7.1` the query can be found in

[open_transactions_geq_DBv71.sql](https://raw.githubusercontent.com/exasol/exa-toolbox/master/utilities/open_transactions_geq_DBv71.sql) 

The query determines the approximate lock status of each session and does a risk evaluation on the basis of idle times and open transaction locks. Session with open transactions being idle for over an hour typically start to cause stated effects.

In the following example



| HAS_LOCKS | EVALUATION | SESSION_ID | USER_NAME | STATUS | COMMAND_NAME | DURATION | ... |
| --- | --- | --- | --- | --- | --- | --- | --- |
|  4 | SYS | IDLE | NOT SPECIFIED | 0:00:02 | ... |
| NONE |  1505059440358261249 | GUEST | IDLE | NOT SPECIFIED | 3:28:20 | ... |
| READ LOCKS |  1505059440023663104 | ADMIN | EXECUTE SQL | SELECT | 0:00:01 | ... |
| WRITE LOCKS |  1505061190567112340 | LOADER | EXECUTE SQL | MERGE | 0:11:02 | ... |
| READ LOCKS | CRITICAL | 1505059543549212162 | ANALYST | IDLE | NOT SPECIFIED | 1:26:19 | ... |
| WRITE LOCKS | VERY CRITICAL | 1505061190568112648 | TESTER | IDLE | NOT SPECIFIED | 2:10:02 | ... |

the sessions 1505061190568112648 and 1505059543549212162 in the example have been idle for some time but did not finish their open transactions.

## Additional References

<https://docs.exasol.com/db/latest/database_concepts/session_management.htm>

<https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_dba_sessions.htm>

<https://www.exasol.com/support/browse/EXASOL-2415>

<https://www.exasol.com/support/browse/EXASOL-1330>

