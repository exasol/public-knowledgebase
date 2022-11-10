# Transaction Conflicts for Mixed Read/Write Transactions 
## Background

Exasol's transaction isolation level is **serializable**, which means that each transaction is carried out as if it was part of a sequence (even though transactions can run in parallel). It is vital to read about and understand [Exasol's Transaction System](https://community.exasol.com/t5/database-features/transaction-system/ta-p/1522) before continuing with this article. 

Serialization helps ensure data consistency, but can also lead to some issues, such as: 

* Transactions that must wait for a commit by an earlier transaction before they can continue (more details [here](https://community.exasol.com/t5/database-features/wait-for-commit-on-select-statement/ta-p/1717))
* Transaction collisions for mixed read/write transactions, which result in a forced rollback of a transaction

This section focuses on the second point – how collisions occur in mixed read/write transactions, and ways to prevent them. 

## How Transaction Collisions Occur

Certain concurrent transactions are related in terms of the database objects they impact. Complex scenarios that mix read and write operations could result in complicated relationships between transactions, and thus more chance of conflicts. To demonstrate how conflicts can occur, let's consider an example.

**Example 1 - Transaction Collision** This example has three different connections (with AUTOCOMMIT off). The following happens (represented in the table below):

* An ETL process (tr1) updates fact tables (CORE.PRODUCTS and CORE.STOCKS) using data from staging tables (STG.ETL_PRODUCTS and STG.ETL_STOCKS). It also reads from a control table (STG.JOBS) to determine what needs to be done.
* A new transaction (tr2)  changes the control table while tr1 is processing.
* The database is constantly in use by reporting and catalog queries that read multiple objects in a transaction (tr3).

The operations performed by each transaction are shown in the following table:

|Transaction 1 (tr1)   |Transaction 2 (tr2)   |Transaction 3 (tr3)   |Comment   |
|---|---|---|---|
|```select * from STG.JOBS;```   |   |   |   |
|```insert into CORE.PRODUCTS select * from STG.ETL_PRODUCTS;```   |   |   |   |
|```/* the insert takes a while */```   |   |   |   |
|   |```insert into STG.JOBS values (...);```   |   |tr1 < tr2, because tr2 writes to a table that was read by tr1   |
|   |```commit;```   |   |   |
|   |   |```commit;```   |Starts a new transaction --> tr2 < tr3, since tr3 was started after tr2 ended (automatic scheduling).<br>We now have the relations tr1 < tr2 < tr3, which implies tr1 < tr3   |
|   |   |```select * from CORE.STOCKS;```   |   |
|   |   |```select * from CORE.PRODUCTS;```   |This statement ends up in **WAIT FOR COMMIT**, waiting for tr1 to finish writing CORE.PRODUCTS   |
|```insert into CORE.STOCKS select * from STG.ETL_STOCKS;```   |   |   |This statement ends up in a **forced ROLLBACK** because the resulting relation tr1 > tr3 on writing CORE.STOCKS is in conflict to the transitory relation tr1 < tr3   |  

The relations between the transactions are based on the chronological operations:

* tr2 becomes related to tr1 when it writes to a table that tr1 had already read (STG.JOBS).
* tr3 is automatically scheduled to run after tr2 has completed, and has a relation to tr2.
* Because tr2 and tr3 are related, it is implied that tr3 is also related to tr1.

The core concept of serialization - that all related transactions run as if they were sequential - means that the data in the database must be written and read as if the three transactions were run one after another: tr1 => tr2 => tr3.

The principle conflict in this example is caused when tr1 tries to write to CORE.STOCKS after tr3 has read from it. If we focus only CORE.STOCKS, the relations between tr1 and tr3 mean that the changes to the table should occur sequentially as follows: 

1. tr1 writes to CORE.STOCKS
2. tr3 reads from CORE.STOCKS

In reality what happens:

1. tr3 reads from CORE.STOCKS
2. tr1 writes to CORE.STOCKS

This violates the serialization of the transactions, and tr1 is rolled back.

## Potential Strategies to Avoid Transaction Conflicts

Now that we know how transaction conflicts can occur, we can consider several potential workarounds.

## Perform Rollbacks on Database Objects

The conflict in Example 1 is caused by the relationship between transactions caused by the INSERT on STG.JOBS. It is possible to solve that specific problem by performing a rollback on STG.JOBS in tr1. This would mean that a relationship between tr1 and tr2 is not created (tr1's "lock" on STG.JOBS would be rolled back), and thus there is no relationship between tr1 and tr3. This would eliminate the violation of serializability.  
However, although this solves the particular scenario of Example 1, transaction conflicts can still occur when other objects are used. 

**Example 2 - Transaction Collision After Rollback**

This example is similar to Example 1, except tr1 performs a rollback on STG.JOBS after reading from it. This resolves Example 1's problem (not shown in the table below). However, another transaction (tr2) does an insert on a staging table used by tr1 (STG.ETL_PRODUCTS), which results in a simliar transaction collision.

| Transaction 1 (tr1) | Transaction 2 (tr2) | Transaction 3 (tr3) | Comment |
|---|---|---|---|
|```select * from STG.JOBS;```   |   |   |   |
|```rollback;```   |   |   |job cached (ETL-Tool or Lua ELT-Script)   |
|```insert into CORE.PRODUCTS select * from STG.ETL_PRODUCTS;```   |   |   |   |
|```/* the insert takes a while */```   |   |   |   |
|   |```insert into STG.ETL_PRODUCTS values (...);```   |   |tr1 < tr2   |
|   |```commit;```   |   |   |
|   |   |```commit;```   |Starts a new transaction --> tr2 < tr3, since tr3 was started after tr2 ended (automatic scheduling).<br>We now have the relations tr1 < tr2 < tr3 which implies tr1 < tr3   |
|   |   |```select * from CORE.STOCKS;```   |   |
|   |   |```select * from CORE.PRODUCTS;```   |This statement ends up in **WAIT FOR COMMIT**, waiting for tr1 to finish writing to CORE.PRODUCTS.   |
|```insert into CORE.STOCKS select * from STG.ETL_STOCKS;```   |   |   |This statement ends up in a **forced ROLLBACK**, because the resulting relation tr1 > tr3 on writing CORE.STOCKS is in conflict to the transitory relation tr1 < tr3   |

As you can see, despite the rollback on STG.JOBS, a conflict still occurs. This is because tr1 is a mix of read and write statements. Such mixed transactions can have unpredictable results due to other transactions that might run in parallel. Therefore a simple rollback is not a sufficient solution for avoiding conflicts.

## Lock Tables Required for Transactions in Advance

Another approach to preserve serializability is to "reserve" tables that a transaction requires during its processing. In Exasol, this can be done by using the following command: 


```markup
delete from <table> where FALSE;
```
This command does nothing to the table, but if executed at the beginning of the transaction, means that the table is already associated with the transaction. 

To understand how this could solve conflicts, take a look at the cause of the problem in Example 1 above: tr1 only writes to CORE.STOCKS at a much later point in time after the transaction started. In the meantime, tr3 reads from CORE.STOCKS. By the time tr1 inserts on CORE.STOCKS, the serialization has been violated. What you want to do is associate CORE.STOCKS with tr1 right at the beginning. 

To demonstrate how this can be achieved and the results, have a look at Example 3 below.

**Example 3 - Lock Tables for Transaction**

This example is similar to Examples 1 and 2, except tr1 locks all target tables in advance.


| Transaction 1 (tr1) | Transaction 2 (tr2) | Transaction 3 (tr3) | Comment |
|---|---|---|---|
|```select * from STG.JOBS;```   |   |   |   |
|```rollback;```   |   |   |Job cached (ETL-Tool or Lua ELT-Script)   |
|```delete from CORE.PRODUCTS where FALSE;```   |   |   |   |
|```delete from CORE.STOCKS where FALSE;```   |   |   |   |
|```insert into CORE.PRODUCTS select * from STG.ETL_PRODUCTS;```   |   |   |   |
|```--the insert takes a while```   |   |   |   |
|   |insert into STG.ETL_PRODUCTS values (...);   |   |tr1 < tr2   |
|   |commit;   |   |   |
|   |   |   |Starts a new transaction --> tr2 < tr3, since tr3 was started after tr2 ended (automatic scheduling).<br>We now have the relations tr1 < tr2 < tr3 which implies tr1 < tr3   |
|   |   |   |   |
|```insert into CORE.STOCKS select * from STG.ETL_STOCKS;```   |   |   |   |

| Transaction 1 (tr1) | Transaction 2 (tr2) | Transaction 3 (tr3) | Comment |
|  
```
select * from STG.JOBS;
```
  |  
| 
```
rollback;
```
 |  Job cached (ETL-Tool or Lua ELT-Script) |
| 
```
delete from CORE.PRODUCTS  where FALSE;
```
 |  
| 
```
delete from CORE.STOCKS  where FALSE;
```
 |  
| 
```
insert into CORE.PRODUCTS select * from STG.ETL_PRODUCTS;
```
 |  
| /* the insert takes a while */ |  
|  
```
insert into STG.ETL_PRODUCTS  values (...);
```
 |  tr1 < tr2 |
|  
```
commit;
```
 | 
|  
```
commit;
```
 | Starts a new transaction --> tr2 < tr3, since tr3 was started after tr2 ended (automatic scheduling).We now have the relations tr1 < tr2 < tr3 which implies tr1 < tr3 |
|  
```
select * from CORE.STOCKS;
```
 | This statement ends up in**WAIT FOR COMMIT**, waiting for tr1 to finish writing CORE.STOCKS |
| 
```
insert into CORE.STOCKS select * from STG.ETL_STOCKS;
```
 |  **Fine**because no relation via CORE.STOCKS with tr3 (tr1 already has a write-lock on CORE.STOCKS) |

Here the problem is resolved by locking all the tables needed by tr1 in advance, thus preserving the serialization even when other transactions require these tables (other transactions must wait for tr1 to commit before they can use these tables).

**Advantage of this approach**: The rollbacks that occurred at the end of tr1 in Example1 and Example 2 are avoided.

**Disadvantage of this approach**: In this example, tr3's SELECT statement from CORE.STOCKS must wait for tr1 to commit. In a real scenario, this could mean operational activities are delayed while waiting for another transaction to commit. For example, if tr3's SELECT statements are executed by reports, the reports have to wait until tr1 commits.

 When you need to lock multiple tables, it is best practice to always lock them in the same order across all transactions. Otherwise there could still be a small chance of a transaction collision.

## Use EXPORT or IMPORT

This approach involves doing an EXPORT or IMPORT of data, but from the same database. In the example below we will focus on the EXPORT option.

An EXPORT statement is split into two transactions: one for the SELECT of the data, and one for the INSERT. The INSERT is automatically committed. By separating reading and writing into two transactions, the mixed read/write transactions and their potential conflicts are avoided.

Example 4 below demonstrates how an EXPORT statement could be used. 

**Example 4 - EXPORT Statement**

The same scenario as in example 3 but this time the ETL process uses an EXPORT statement to insert data from the same database. The parallel writer again targets the staging table STG.ETL_PRODUCTS (tr2). This example requires a connection ("this") pointing to the same EXASOL DB instance.

When tr1a runs, separate transactions are generated to INSERT the data. In the example below, these are tr1b and tr1c.



| Transaction 1 (tr1a) | Transactions Resulting from EXPORT | Transaction 2 (tr2) | Transaction 3 (tr3) | Comment |
| 
```
select * from JOBS;
```
 |   
| 
```
rollback;
```
 |   Job cached (ETL-Tool or Lua ELT-Script) |
| 
```
export (SELECT * FROM STG.ETL_PRODUCTS)into exa at this table CORE.PRODUCT; 
```
 | **Transaction tr1b**: 
```
insert into CORE.PRODUCTS  values (...);
```
 |  Using the EXPORT causes a new transaction --> tr1a has no read lock on ETL_PRODUCTS |
| /* the select takes a while */ | /* the insert takes a while*/ |  
|  
```
insert into STG.ETL_PRODUCTS  values (...);
```
 |  tr1a < tr2; no relation to tr1b |
|  
```
commit;
```
 | 
|   
```
commit;
```
 | Starts a new transaction --> tr2 < tr3, since tr3 was started after tr2 ended (automatic scheduling). We now have the relations tr1a < tr2 < tr3, which implies tr1a < tr3 |
|   
```
select * from CORE.STOCKS;
```
 | 
|  
```
commit;
```
 **tr1b completed** |  
```
select * from CORE.PRODUCTS;
```
 | The result of this SELECT statement depends on when the automatic commit for tr1b occurs:* tr1b commit occurs before SELECT => relation tr1b < tr3, and the new version of data is read
* SELECT occurs before tr1b commit => relation tr1b > tr3 and old version of data is read

There is no wait for commit in either case. |
| 
```
export (SELECT * FROM STG.ETL_STOCKS)  into exa at this table CORE.STOCKS;
```
 | **Transaction tr1c**: 
```
INSERT into CORE.STOCKS  values (...);
```
 |  **Fine**, because tr3 < tr1c  |

**Advantage of this approach**: There are several advantages:

* There are no collisions in this example
* The data read by the ETL job (tr1a) is consistent
* No related wait for commits (and thus no blocked reports as in Example 3)

**Disadvantage of this approach**: The transaction context is lost when you do an EXPORT like this. This means that if something goes wrong in tr1a, it might not be possible to roll back the transactions resulting from the EXPORT. An additional disadvantage is that although there are no issues for the SELECT queries, there is no guaranteed consistency for multiple table writes.

### Using IMPORT

You can achieve a similar result to Example 4 by using IMPORT. In this case, the initial transaction handles the writing of the data while the resulting transaction handles the SELECT. 

The advantage of this option is that it is possible to fully roll back the transaction at any point. The disadvantage is that there is a chance the imported data is less consistent as in the EXPORT option, because each SELECT statement is a separate transaction. For example: the data read from STG.ETL_STOCKS might be more recent than from STG.ETL_PRODUCTS.

## Additional References

* [Exasol's Transaction System](https://docs.exasol.com/database_concepts/transaction_management.htm)
* [System Tables and Transaction Conflicts](https://community.exasol.com/t5/database-features/filter-on-system-tables-and-transaction-conflicts/ta-p/1232)
* [Determining Idle Sessions with Open Transactions](https://community.exasol.com/t5/database-features/how-to-determine-idle-sessions-with-open-transactions/ta-p/1238)
* [Wait for Commit on SELECT Statements](https://community.exasol.com/t5/database-features/wait-for-commit-on-select-statement/ta-p/1717)

"
