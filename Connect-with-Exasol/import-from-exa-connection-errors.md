# IMPORT FROM EXA: Connection Errors 
## Scope

While loading data from one Exasol database into another database, you may get connection issues. This article will describe how you can resolve these.

## Diagnosis

If you run an IMPORT FROM EXA command, you are affected by this problem if you see an error message which looks like:


```markup
[Code: 0, SQL State: 42636]  ETL-4212: Parallel connection from n0010.c0001.exacluster.local to external EXASolution at <host>:20386 failed. [Connection attempt timed out No server listening.] (Session: 1692134639113732096)
```
## Explanation

In order to load data into Exasol from another database, there are three interfaces available:

1. JDBC - can be used with most DBMS's
2. EXA - can be used with other Exasol Databases
3. ORA - can be used with Oracle databases

You choose the interface in your IMPORT or EXPORT statement:


```markup
IMPORT FROM <INTERFACE> AT <CONNECTION NAME> ...  -- Example  IMPORT FROM JDBC AT 'JDBC_CONNECTION' ... IMPORT FROM EXA AT 'EXA_CONNECTION' ... IMPORT FROM ORA AT 'ORA_CONNECTION' ...
```
The EXA interface uses a different interface in order to parallelize the connection and improve the performance. Generally, IMPORT FROM EXA is faster than IMPORT FROM JDBC. This interface, however, will use a different port range compared to a regular JDBC connection. Specifically, IMPORT FROM EXA uses the port range 20000-21000. Whenever these ports are not opened, you will receive the error message above. It is not possible to choose a singular port to open - the entire range needs to be opened because the chosen port differs for each query. It is not possible to influence which port number the IMPORT FROM EXA uses. 

## Recommendation

In order to solve this problem, we recommend to open the port range 20000-21000 in both the source and target databases, so that they can communicate using the EXA interface.

If this is not possible or will take a while to be implemented, you can use the JDBC interface as a workaround. To do this, you can create a new connection which references a JDBC connection string. For example:


```markup
-- EXA connection CREATE CONNECTION EXA_DB TO '<ip address> USER 'username' IDENTIFIED BY 'password';  -- JDBC connection CREATE CONNECTION EXA_DB_JDBC TO 'jdbc:exa:<ip address>:8563' user 'username' identified by 'password';
```
 Now, in your IMPORT statement, you can use the IMPORT FROM JDBC syntax instead of IMPORT FROM EXA:


```markup
-- IMPORT using EXA interface IMPORT INTO TABLE1 FROM EXA AT EXA_DB STATEMENT '...';  -- New IMPORT using JDBC interface IMPORT INTO TABLE1 FROM JDBC AT EXA_DB_JDBC STATEMENT '...';
```
 The JDBC interface will likely have slower performance than the EXA interface. Once the ports are opened, we recommend to use the EXA interface whenever possible.

## Additional References

* [List of default ports](https://docs.exasol.com/administration/on-premise/installation/prepareenvironment/cluster_network_access.htm#DefaultPorts)
* [IMPORT syntax](https://docs.exasol.com/sql/import.htm)
* [Loading Data Best Practices](https://docs.exasol.com/loading_data/best_practice.htm)
