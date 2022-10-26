# Parallel connections with JDBC 
## Questions

* **What data can you read using subconnections?**
* **What data can you insert using subconnections?**
* **How to establish parallel connections?**
* **What about transactions in parallel mode?**
* **What about transactions in parallel mode?**

## Answer

You can use subconnections to read or insert data in parallel from and into the Exasol server.  
This will increase performance considerably.

Using this interface you can read/write data in parallel from different physical hosts or from different processes or in one process from different threads.

**What data can you read using subconnections?**  
You need a statement that produces a large result set. The result set can be then retrieved in parts from the parallel connections. For small results this interface has no advantage.

**What data can you insert using subconnections?**  
Like when reading data, using this interfaces only makes sense if you want to insert large amounts of data. You can simply insert rows into a table in EXASOL using a prepared insert statement. The data coming through the parallel connections will be put together by the server into the right table.

**How to establish parallel connections?**  
First you need a normal JDBC connection. On this you can use the methodEnterParallel()to start operating with subconnections. You will receive connection strings for all new parallel connections you can start now. Start the subconnections with auto commit off. After this you can start reading or sending data, nearly like in a normal connection.

**Attention**: You can specify the maximum number of subconnections inEnterParallel(). This number may be reduced by the server because only one subconnection is allowed per database node.  
You have to establish the subconnections by using all connection strings received fromGetWorkerHosts(). Subconnections can only be used after all connections have been established.

**What about transactions in parallel mode?**  
Start the subconnections with auto commit off.  
Commits should be made only on the main connection after the subconections have inserted all data and they have closed the prepared statements.

**An Java example is attached.**  
In the example a main connection reads the connection strings for the subconnections from the server. For each subconnection a thread is started that inserts a few rows. Commit is executed on the main connection. Then other threads read the data from the table.

