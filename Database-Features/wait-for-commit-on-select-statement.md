# WAIT FOR COMMIT on SELECT statement

## Background

### Cause and Effect

Since Exasol's transaction isolation level is SERIALIZABLE and newly created transactions are automatically scheduled after finished transactions, it is possible that WAIT FOR COMMITS occur for pure read transactions (consisting of SELECT statements, only).

## Explanation

## How to reproduce

Three different connections (having AUTOCOMMIT off) are needed to reproduce this situation:

### Example 1

If a long running transaction (nr. 1 in table below) reads object A and writes object B (e.g. long running IMPORT statements) and a second transaction (2 in table) writes object A and commits in parallel, Tr2 is scheduled after.
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

### Example 2

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

## Workarounds

In case when transaction T1 can't be broken up into multiple transactions (i.e. MERGE or INSERT from SELECT), there are still some workarounds to consider in order to avoid or alleviate the WAIT FOR COMMIT conflict.

### 1. Lock ALL Tables Required for Transactions T1 in Advance

The main idea here is to impose WRITE locks on all objects involved in the T1 transaction — even those that are only being read. This can be achieved using the following command: 

```sql
delete from <table> where FALSE;
```

This command does nothing to the table, but if executed at the beginning of the transaction, it will associate the table with the transaction. Also you should ensure that **autocommit** is off in this T1 transaction, otherwise by default all DML statements (including those DELETEs ) will be performed in a separate transactions, and this won't lock the corresponding objects for T1.

Basically the idea is to prevent the in-the-middle transaction T2 (the one that eventually enforces the order of transactions T1<T2<T3) from changing the Read-locked objects of T1. This means that now T2 transaction will be waiting for T1 to end, before writing into PSA_VISTA.TBLSESSIONATTRIBUTE.

This of course will also be a WAIT_FOR COMMIT but, now it will be in writing transaction T2 (probably some ETL process) and not in the reading transaction T3 which is a user query which is much more critical to have a quick response.

You can find more information and examples of this approach in the following article: [Transaction Conflicts for Mixed Read/Write Transactions](https://exasol.my.site.com/s/article/Transaction-Conflicts-for-Mixed-Read-Write-Transactions)

### 2. Use IMPORT statements to read conflicted TABLEs in T1

The first option of course could be complicated and inconvenient, because it supposes that all objects underneath the T1 transaction should be identified and explicitly locked by T1. If there are a lot of objects involved, it could be tricky to lock them all in advance. Additionally this could significantly increase waiting in ETL processes. 

Alternatively you can use IMPORT statements to read the conflicted tables in T1. This will ensure that those table are read in a separate transactions, thus will not be READ locked by T1, and T2 will not trigger the strict transactional order.

In order to do so, please follow these steps:
- identify a conflict tables. In previous example it was PSA_VISTA.TBLSESSIONATTRIBUTE
- Create a EXA connection form your DB to itself.

```sql
--For example
CREATE OR REPLACE CONNECTION EXA_SELF TO 'exa:<CONNECTION_STRING>'  USER '<USER>' IDENTIFIED BY '<PASSWORD>';
```

- In T1, instead of just reading this table, use the subquery with IMPORT FROM EXA, to read the table in a separate transaction.

```sql
-- for example, instead of this query
select * from
TEMP.TAB1 t1 join TEMP.TAB2 t2
on t1.x = T2.x;

-- try using the query with IMPORT in subselect
select * from
TEMP.TAB1 t1 join
(
SELECT * FROM (
IMPORT INTO (x VARCHAR(20)) FROM EXA
    AT EXA_SELF
    TABLE TEMP.TAB2)
) t2
on t1.x = T2.x;
```

This will prevent the mixed read/write conflict. But this logic could complicate the initial SQL query and make it performance overall worse than before. Even though, IMPROT from EXA provides a best optimization compared to other IMPORTs, it's still not as fast as just simply reading the table.

### 3. Using a buffer temp table in T1

Last but not least, there's a classic approach: separating T1 from T3 by minimizing the time during which they compete for the shared object.

Let's concider the following example

| Transaction 1              | Transaction 2 | Transaction 3 | Comment |
|----------------------------|---|---|---|
| insert into tab2 select * from view1; |   |   |   |
| – view1 is heavy and have a lot of objects underneath including some tab1 table |   |   |   |
| – transaction remains open |   |   |   |
|                            |insert into tab1 values 1;   |   |Transaction 1 < Transaction 2   |
|                            |commit;   |   |   |
|                            |   |commit;   |Starts a new transaction (Transaction 2 < Transaction 3)   |
|                            |   |select * from tab2;   |This statement ends up in WAIT FOR COMMIT, waiting for Transaction 1   |

The idea is simple yet effective — instead of having T1 write directly to **tab2**, let it write to a temporary table first. Typically, the majority of time is spent executing the underlying SELECT statement rather than performing the final INSERT.

By delaying the writing to the target table until the very end, T1 holds a lock on **tab2** only briefly. This significantly reduces the window of concurrency between T1, T2, and T3, lowering the likelihood of conflicts. And even if a conflict does occur, the waiting time will be considerably shorter.

For example, instead of

```sql
insert into tab2 select * from view1;
```

try to do it like this

```sql
-- long execution time of the heavy view execution and materialization, but target table isn't WRITE locked yet
INSERT INTO tmp_tab2 SELECT * view1;

--fast insert from TMP into target table
INSERT INTO tab2 SELECT * FROM tmp_tab2;
```

This technique doesn't require any changes in the views, doesn't need a complicated analysis of the potential conflict tables, and could significantly alleviate the WAIT FOR COMMIT conflicts. But it doesn't prevent the conflicts from happening.


## Additional References

1. [Transaction System](https://exasol.my.site.com/s/article/Transaction-System)
2. [Filter on system tables and transaction conflicts](https://exasol.my.site.com/s/article/Filter-on-system-tables-and-transaction-conflicts)
3. [Investigating Transaction Conflicts using Auditing](https://exasol.my.site.com/s/article/Investigating-Transaction-Conflicts-using-Auditing)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 
