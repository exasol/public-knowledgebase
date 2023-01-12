# WAIT FOR COMMIT on SELECT statement 
## Background

### Cause and Effect:

Since Exasol's transaction isolation level is SERIALIZABLE and newly created transactions are automatically scheduled after finished transactions, it is possible that WAIT FOR COMMITS occur for pure read transactions (consisting of SELECT statements, only). 

## Explanation

## How to reproduce:

Three different connections (having AUTOCOMMIT off) are needed to reproduce this situation:

#### Example 1:

If a long running transaction (nr. 1 in table below) reads object A and writes object B (e.g. long running IMPORT statements) and a second transaction (2 in table) writes object A and commits in parallel, Tr2 is scheduled after   
Tr1 logicallym, but does not have to actually wait. After Tr2 is committed all new transactions are scheduled after it. If such a new transaction (3 below) wants to read object B it now has to wait for the commit of our inial transaction 1:

| Transaction 1              | Transaction 2 | Transaction 3 | Comment |
|----------------------------|---|---|---|
| select * from tab1;        |   |   |   |
| insert into tab2 values 1; |   |   |   |
| – transaction remains open |   |   |   |
|                            |insert into tab1 values 1;   |   |Transaction 1 < Transaction 2   |
|                            |commit;   |   |   |
|                            |   |commit;   |Starts a new transaction (Transaction 2 < Transaction 3)   |
|                            |   |select * from tab2;   |This statement ends up in WAIT FOR COMMIT, waiting for Transaction 1   |

#### Example 2:

The same situation may occur if you query **system tables** while SqlLogServer is performing one of its tasks (e.g. "DB size task" determining the database size). The following example describes this situation:

| Transaction 1 | LogServer                                    | Transaction 3 | Comment |
|---|----------------------------------------------|---|---|
|select * from EXA_DB_SIZE_LAST_DAY;   |                                              |   |   |
|insert into tab1 values 1;   |                                              |   |   |
|– transaction remains opened   |                                              |   |   |
|   | – DB size task (writes EXA_DB_SIZE_LAST_DAY) |   |Transaction 1 < LogServer transaction, the task is executed every 30 minutes (0:00, 0:30, 1:00, 1:30, ...)   |
|   | commit;                                      |   |   |
|   |                                              |commit;   |Starts a new transaction (LogServer transaction 2 < Transaction 3)   |
|   |                                              |select * from EXA_DB_SIZE_LAST_DAY;   |This statement end up in WAIT FOR COMMIT   |

Please note that the problem around system tables has been mitigated by introducing [automated metadata snapshot execution](https://exasol.my.site.com/s/article/Changelog-content-10122) in Exasol 7.0.

## Solution

Currently, the only solution to this is to break up Transaction 1 into multiple transactions by performing a COMMIT or ROLLBACK after the initial read access.  
However, things may get more complicated when the read/write operation is concentrated within a single statement (ie. MERGE or INSERT from SELECT). In the latter case it has proven helpful to 'outsource' the reading part by using IMPORT as a subselect to fetch required data through a separate transaction...

## Additional References

1. <https://exasol.my.site.com/s/article/Transaction-System>
2. <https://exasol.my.site.com/s/article/Filter-on-system-tables-and-transaction-conflicts>
3. <https://exasol.my.site.com/s/article/Investigating-Transaction-Conflicts-using-Auditing>
