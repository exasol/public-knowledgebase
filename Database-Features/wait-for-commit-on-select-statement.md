# WAIT FOR COMMIT on SELECT statement 
## Background

### Cause and Effect:

Since Exasol's transaction isolation level is SERIALIZABLE and newly created transactions are automatically scheduled after finished transactions, it is possible that WAIT FOR COMMITS occur for pure read transactions (consisting of SELECT statements, only). 

## Explanation

## How to reproduce:

Three different connections (having AUTOCOMMIT off) are needed to reproduce this situation:

#### Example 1:

If a long running transaction (Tr1) reads object A and writes object B (e.g. long running IMPORT statements) and a second transaction (Tr2) writes object A and commits in parallel, Tr2 is scheduled after   
Tr1. AfterTr2 is commited all new transactions are scheduled after it. If such a transaction wants to read object B it has to wait for the commit of Tr1.

| Transaction 1 | Transaction 2 | Transaction 3 | Comment |
|---|---|---|---|
|select * from tab1;   |   |   |   |
|– transaction remains opened   |   |   |   |
|   |insert into WFC.tab1 values 1;   |   |Transaction 1 < Transaction 2   |
|   |commit;   |   |   |
|   |   |commit;   |Starts a new transaction (Transaction 2 < Transaction 3)   |
|   |   |select * from tab2;   |This statement ends up in WAIT FOR COMMIT, waiting for Transaction 1   |

#### Example 2:

The same situation may occur if you query **system tables** while SqlLogServer is performing one of its tasks (e.g. "DB size task" determining the database size). The following example describes this situation:

| Transaction 1 | LogServer | Transaction 3 | Comment |
|---|---|---|---|
|select * from EXA_DB_SIZE_LAST_DAY;   |   |   |   |
|insert into tab1 values 1;   |   |   |   |
|– transaction remains opened   |   |   |   |
|   |– DB size task (writes EXA_DB_SIZE_LAST_DAY)   |   |   |
|   |   |commit;   |   |
|   |   |select * from EXA_DB_SIZE_LAST_DAY;   |   |


## Solution

Currently, the only solution to this is to break up Transaction 1 into multiple transactions by performing a COMMIT or ROLLBACK after the initial read access.  
However, things may get more complicated when the read/write operation is concentrated within a single statement (ie. MERGE or INSERT from SELECT). In the latter case it has proven helpful to 'outsource' the reading part by using IMPORT as a subselect to fetch required data through a separate transaction...

## Additional References

<https://community.exasol.com/t5/database-features/transaction-system/ta-p/1522>

<https://community.exasol.com/t5/database-features/filter-on-system-tables-and-transaction-conflicts/ta-p/1232>

