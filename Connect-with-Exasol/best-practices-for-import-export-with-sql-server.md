# Best Practices for IMPORT/EXPORT with SQL Server 
## Table of contents:

## Background

When transferring data between SQL Server and Exasol, there are two different drivers you could choose from which requires different syntax. The following examples show how one can import data into Exasol from MS SQL Server and export data from Exasol into MS SQL Server. 

## Explanation

## JTDS Driver

For performance reasons, we recommend using the [**jTDS JDBC driver for SQL Server**](https://sourceforge.net/projects/jtds/). In versions 6.1 and 6.2, this is preinstalled. However, if you need to [install the driver in Exaoperation](https://docs.exasol.com/loading_data/connect_databases/import_data_using_jdbc.htm), you can download the driver and add it with this information:

* Main Class: net.sourceforge.jtds.jdbc.Driver
* Prefix: jdbc:jtds:sqlserver:

**Beware**: If you do single loads with more than 4,294,967,295 rows, you should use the MSSQL native JDBC driver due to a bug in JTDS (note that the number 4,294,967,295 is the maximum value for a 32-bit unsigned integer). If you used JTDS for such big loads, only 4,294,967,295 rows would be imported, and the rest would be ignored without seeing an error.

From version 6.1 onwards, you will also need the system privileges IMPORT/EXPORT to be granted to your user (or one of it's roles). For example:


```markup
grant import,export to public;
```
You can create a connection object to SQL Server and use this in your import statements:


```markup
CREATE CONNECTION conn_jtdsmssql  TO 
 'jdbc:jtds:sqlserver://dbserver;databaseName=testdb'  
 USER 'user1' 
 IDENTIFIED BY 'user1pw';
```
It is also possible to use Windows Authentication in conjunction with this driver. In order to enable this authentication, simply add the parameters "useNTLMv2=true" and "domain=[Domain name]", like so:


```"code-sql"
CREATE CONNECTION conn_jtdsmssql TO 
 'jdbc:jtds:sqlserver://<host>:1433;DatabaseName=<db name>;domain=AD;useNTLMv2=true;' 
 USER 'username' -- Windows Username 
 IDENTIFIED BY 'AD password here' --Windows password; 
```
Once the AD user/password are defined in the database connection (USER '' IDENTIFIED BY ''), they can be re-used as often as needed (as long as the credentials are valid). Please note that the passwords are masked in all SQL texts and logs. With this method, you can grant the connection only to the required users on EXASOL side and it can be used to IMPORT data from SQL server. 

Once your connection is created, you can test the connectivity by querying the SQL Server system catalog:


```markup
select * from  
 ( import from jdbc at conn_jtdsmssql statement 'select * from information_schema.tables'  );
```
If your connection is successful, you're ready to IMPORT/EXPORT data from SQL Server! IF it's not, please check your network settings and/or the settings of your SQL Server instance. Using the JTDS driver, one could import/export data using the following commands:


```"code-sql"
IMPORT INTO table1 FROM JDBC DRIVER='JTDSMSSQL'  
 AT 'jdbc:jtds:sqlserver://dbserver;databaseName=testdb'  
 USER 'user1' 
 IDENTIFIED BY 'user1pw' TABLE table2;  
 
EXPORT table1 INTO JDBC DRIVER='JTDSMSSQL' 
 AT 'jdbc:jtds:sqlserver://dbserver;databaseName=testdb'  
 USER 'user1' 
 IDENTIFIED BY 'user1pw' TABLE table2;  
  
IMPORT INTO table1 FROM JDBC DRIVER='JTDSMSSQL'  
 AT conn_jtdsmssql TABLE table2;  
  
EXPORT table1 INTO JDBC DRIVER='JTDSMSSQL'  
 AT conn_jtdsmssql TABLE table2;
```
## Microsoft SQL Server Driver

If you wish to use the official SQL Server driver, you need to install it first. You can download it from the [Microsoft Download Portal](https://docs.microsoft.com/en-us/sql/connect/jdbc/microsoft-jdbc-driver-for-sql-server) and [install it as a new driver](https://docs.exasol.com/loading_data/connect_databases/import_data_using_jdbc.htm) with the following parameters:

* Source: Path to the MSSQL driver (sqljdbc4.jar)
* Class: com.microsoft.sqlserver.jdbc.SQLServerDriver
* Prefix: jdbc:sqlserver:
* Name: MSSQL

![](images/image.png)

From version 6.1 onwards, you will also need the system privileges IMPORT/EXPORT to be granted to your user (or one of it's roles). For example:


```markup
grant import,export to public;
```
#### Basic Syntax

Using**Microsoft's JDBC driver for SQL Server**, one could import/export data using the following commands:


```"code-sql"
IMPORT INTO table1  FROM JDBC DRIVER='MSSQL'  
 AT 'jdbc:sqlserver://dbserver;databaseName=testdb'  
 USER 'user1' IDENTIFIED BY 'user1pw' TABLE table2;  
 
EXPORT table1 INTO JDBC DRIVER='MSSQL'  
 AT 'jdbc:sqlserver://dbserver;databaseName=testdb'  
 USER 'user1' IDENTIFIED BY 'user1pw' TABLE table2; 
```
A**connection**could also be created and used:


```"code-sql"
CREATE CONNECTION conn_mssql  TO 
'jdbc:sqlserver://dbserver;databaseName=testdb'  
USER 'user1' IDENTIFIED BY 'user1pw';  

IMPORT INTO table1 FROM JDBC DRIVER='MSSQL'  AT conn_mssql TABLE table2; 

EXPORT table1  INTO JDBC DRIVER='MSSQL' AT conn_mssql TABLE table2;
```
Once your connection is created, you can test the connectivity by querying the SQL Server system catalog like before:


```markup
select * from  
 ( import from jdbc at conn_mssql statement 'select * from information_schema.tables'  );
```
Please note, that usage of the newly created connection requires either a system privilege USE ANY CONNECTION or the connection has to be explicitly granted to the user. Connections are automatically granted to the creator, including the ADMIN OPTION.

## Additional References

* [Exasol Documentation](https://docs.exasol.com/loading_data/connect_databases/sql_server.htm)
* [JTDS Documentation](http://jtds.sourceforge.net/faq.html)
* [SQL Server JDBC Documentation](https://docs.microsoft.com/en-us/sql/connect/jdbc/microsoft-jdbc-driver-for-sql-server?view=sql-server-ver15)
* [IMPORT](https://docs.exasol.com/sql/import.htm)
* [EXPORT](https://docs.exasol.com/sql/export.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 