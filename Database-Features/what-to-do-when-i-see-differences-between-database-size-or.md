# What to do, when I see differences between database size or storage space increases steadily 
## Problem

Sometimes, the disk space used by the database may continue to increase, but there was not any data added to the database. This can cause the database to use 100% of the hard drive space and not be able to expand any further.  After a restart, the disk usage is back to normal.

When running out of space, you may notice the following error message in Exaoperation:

> 2021-04-30 10:35:38.005042 Error cluster1 DB: demo, persistent - **usage: 98.57%**, free: 72.75 GiB, max: 5090.38 GiB

The difference between the size of the database in Exaoperation and the sum of all objects may be considerable. In this example, the database size in Exaoperation is 2 TiB, but the sum of all objects is actually only around 1,3 TiB when we ran the below query. 


```sql
SELECT SUM( MEM_OBJECT_SIZE )/(1024*1024*1024) AS GB 
FROM EXA_STATISTICS_OBJECT_SIZES;
```
The "missing" size is attributed to "phantom data" and is 0,7TiB in our example.

## Diagnosis

To check if the problem is caused by phantom data, you have to execute the following query:


```sql
SELECT
    measure_time,
    COMMIT_SIZE,
    MEM_SIZE,
    MULTICOPY_SIZE,
    COMMIT_SIZE-MEM_SIZE-MULTICOPY_SIZE                    PHANTOM_SIZE,
    CAST((local.PHANTOM_SIZE)*100/(MEM_SIZE+MULTICOPY_SIZE) AS DEC(7,3)) "PHANTOM_%"
FROM
    (
        SELECT
            CAST(COMMITTED_SIZE/1024/1024 AS DEC(12,1)) COMMIT_SIZE,
            CAST(MULTICOPY_DATA/1024/1024 AS DEC(12,1)) MULTICOPY_SIZE,
            CAST((MEM_OBJECT_SIZE+INDICES_MEM_SIZE+STATISTICS_SIZE)/1024/1024 AS DEC(12,1))
            MEM_SIZE,
            T.*
        FROM
            "$EXA_STATS_DB_SIZE" T)
    --where measure_time <insert filter on measure_time here>
ORDER BY
    MEASURE_TIME DESC;
```

Huge phantom percentage (>5%) for longer periods of time and especially consistent upwards trend are not normal.

Example:

| MEASURE_TIME | COMMIT_SIZE | MEM_SIZE | MULTICOPY_SIZE | PHANTOM_SIZE | PHANTOM_% |
| --- | --- | --- | --- | --- | --- |
| 2020-10-21 09:48:52 | 1274.7 | 979.4 | 0.0 | 295.3 | **30.151** |
| 2020-10-21 09:30:03 | 1274.8 | 979.5 | 0.0 | 295.3 | **30.148** |
| 2020-10-21 09:29:00 | 1274.8 | 979.5 | 0.0 | 295.3 | **30.148** |
| 2020-10-21 09:27:33 | 998.1 | 979.4 | 0.0 | 18.7 | 1.909 |

## Explanation

Exasol ensures multi-user capability through the implementation of a transaction management system (TMS). This means that requests from different users can be processed in parallel. Each transaction returns a correct result and leaves the database in a consistent state. To ensure this, the transaction must comply with ACID principles:

* **Atomicity**: The transaction is either fully executed or not at all.
* **Consistency**: The transaction is given the internal consistency of the database.
* **Isolation**: The transaction is executed as if it is the only transaction in the system.
* **Durability**: All changes to a completed transaction confirmed with COMMIT remain intact.

Phantom data can be caused by transactions left open (sessions whose last statement was not a COMMIT or ROLLBACK) for a long period of time. In the following, we'll denote the "phantom data" data that is on disk yet it is not counted in any system table.

## How Phantom Data appears:

The reason why this is happening is very similar to what happens in the simple example below:

| Step id | Transaction 1 (TR1) | Transaction 2 (TR2) | Comments |
|---|---|---|---|
|1   |select from T   |   |Read-locks table T   |
|2   |   |Create or replace table T   |Create or replace first drops T and then creates new table T; <br />Now we have two distinct tables T, on visible in TR1 and one in TR2   |
|3   |   |commit   |Version V2 of T is commited. Thus, we see this as increasing commit_data we have V1 of T1 and V2 of T1 commited;<br />Result:<br />Now we would see this as "an increase of "PHANTOM_%"  in our PHANTOM_%-query  	   |
|4   |commit   |   | 	TR1 commited. This TR1 does not need the old copy V1 of T. We can observe this in increasing the COMMIT_SIZE. COMMIT_SIZE contains now only the size of V2 of T<br /> Result: <br />Now we would see this as "an decrease of "PHANTOM_%"  in our PHANTOM_%-query   |

After step 3 (commit TR2) has been executed we have two tables T: one used by TR1 and visible to TR1 and another one which was created and committed by TR2 visible to all transactions that start after TR2 has committed; this can be easily checked by looking up the TABLE_OBJECT_ID column in EXA_ALL_TABLES in TR1 and TR2 - the OBJECT_IDs in both tables are different because TR2 dropped T and created a freshly new table named 'T'. At this point the data blocks of T used by TR1 are "phantom data" that exists on disk but is not visible in EXA_DBA_OBJECT_SIZES - doing `select sum(mem_object_size) from EXA_DBA_OBJECT_SIZES` considers only the blocks as seen by TR2, because that's any new transaction sees the table created by TR2 and not the original one as used in TR1.

While the example is simple, it does show the effects that transactions forgotten open may incur (if either TR1 or TR2 never commits then the "phantom data" will never be reclaimed because it is rightly seen as in use).

Where that query shows data as "phantom" is when all the data blocks are recreated in parallel transactions, because in such case we don't deal with data blocks in two versions, but instead we have one transaction which drops and creates data blocks. Sample queries to create such "phantoms" (in the above scenario replace the update statement in TR2):

* create or replace table - we have different objects in different sessions hence different blocks
* alter table ... partition by,
* alter table ... distribution by,
* recompress table ...,
* reorganize table ... - these drop old blocks and create completely new ones due to efficiency reasons

If the last statement was not a COMMIT or ROLLBACK, any locks on objects are active. Leaving transactions opened (especially with the above statements) will likely lead to such scenarios.

## Resolution Steps

## Restart the database

The simplest solution is to restart the database. In the long term, this may not solve the problem if users keep forgetting to end transactions with a commit or rollback.

## Check for long-running transactions with read operations

Thus, we recommend running the above on a regular basis.

If it reaches say ~ **5-10%** then, you may, look for **READ**-transactions that are open for a long time since this is in most cases the cause of the problem (please refer to [How to determine idle sessions with open transactions (Except Snapshot Executions)](https://exasol.my.site.com/s/article/How-to-determine-idle-sessions-with-open-transactions-Except-Snapshot-Executions)).  
A small phantom percentage (<5%) is normal, a large one is also normal but for short periods of time (if create or replace, reorganize, partition by, distribute by, recompress statements are run on large tables).

Example:



| HAS_LOCKS | EVALUATION | SESSION_ID | USER_NAME | EFFECTIVE_USER | STATUS | COMMAND_NAME |
| --- | --- | --- | --- | --- | --- | --- |
|   |   | 4 | SYS | SYS | IDLE | NOT SPECIFIED |
| NONE |   | 1681170030816657408 | SYS | SYS | IDLE | NOT SPECIFIED |
| **READ LOCKS** | **CRITICAL** | **1681170037604745216** | SYS | SYS | IDLE | NOT SPECIFIED |
| NONE |   | 1681170049143799808 | SYS | SYS | IDLE | NOT SPECIFIED |
| NONE |   | 1681170070620602368 | SYS | SYS | IDLE | NOT SPECIFIED |
| READ LOCKS |   | 1681170092074139648 | SYS | SYS | EXECUTE SQL | SELECT |
| NONE |   | 1681171633878925312 | SYS | SYS | IDLE | NOT SPECIFIED |
| NONE |   | 1681172167982776320 | SYS | SYS | IDLE | NOT SPECIFIED |

Look maybe at EXA_DBA_AUDIT_SQL


```sql
SELECT * FROM EXA_DBA_AUDIT_SQL WHERE SESSION_ID = 1681170037604745216;
```
Result:



| SESSION_ID | START_TIME | STOP_TIME | SUCCESS | SQL_TEXT |
| --- | --- | --- | --- | --- |
| 1681170037604745216 | 2020-10-21 13:58:08 | **2020-10-21 13:58:08** | true | select * from test.t limit 1000 |

⇉ No commit or rollback;


```sql
SELECT * from EXA_DBA_OBJECTS WHERE OBJECT_NAME='T' AND  ROOT_NAME='TEST';
```
Result:



| OBJECT_TYPE | OBJECT_NAME | CREATED | LAST_COMMIT | OWNER | OBJECT_ID | ROOT_NAME |
| --- | --- | --- | --- | --- | --- | --- |
| TABLE | T | **2020-10-21 14:31:58** | 2020-10-21 14:33:29 | SYS | 428670976 | TEST |

This example depicts that an old version of Table `Test.T` at 2020-10-21 13:58:08 was read. This session does not have a commit or rollback and has to hold the old version of T, even though `Test.T` was newly created at 2020-10-21 14:31:58. The reason for this is the ACID principle: The transaction in session 1681170037604745216 is executed as if it is the only transaction in the system. 

## Additional References

* [How to determine idle sessions with open transactions (Except Snapshot Executions)](https://exasol.my.site.com/s/article/How-to-determine-idle-sessions-with-open-transactions-Except-Snapshot-Executions)
* [Transaction Management](https://docs.exasol.com/database_concepts/transaction_management.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 