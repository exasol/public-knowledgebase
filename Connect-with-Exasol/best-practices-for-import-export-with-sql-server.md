# Best Practices for IMPORT/EXPORT with SQL Server

## Background

When transferring data between SQL Server and Exasol, there are two different drivers you could choose from which require different syntax. The following examples show how one can import data into Exasol from MS SQL Server and export data from Exasol into MS SQL Server.

## Explanation

### JTDS Driver

Driver installation procedure is explained in [Load data from Microsoft SQL Server / Add JDBC driver](https://docs.exasol.com/db/latest/loading_data/connect_sources/sql_server.htm#AddJDBCdriver).

[**jTDS JDBC driver for SQL Server**](https://sourceforge.net/projects/jtds/) might have better performance than Microsoft SQL Server Driver. At the same time jTDS JDBC driver for SQL Server doesn't receive updates since several years.

**Beware**: If you do single loads with more than 4,294,967,295 rows, you should use the MSSQL native JDBC driver due to a bug in JTDS (note that the number 4,294,967,295 is the maximum value for a 32-bit unsigned integer). If you use JTDS for such big loads, only 4,294,967,295 rows would be imported, and the rest would be ignored without seeing an error.

From version 6.1 onwards, you will also need the system privileges IMPORT/EXPORT to be granted to your user (or one of it's roles). For example:

```sql
grant import,export to MY_USER;
```

You can create a connection object to SQL Server and use this in your import statements:

```sql
CREATE CONNECTION conn_jtdsmssql  TO 
 'jdbc:jtds:sqlserver://dbserver;databaseName=testdb'  
 USER 'user1' 
 IDENTIFIED BY 'user1pw';
```

It is also possible to use Windows Authentication in conjunction with this driver. In order to enable this authentication, simply add the parameters "useNTLMv2=true" and "domain=[Domain name]", like so:

```sql
CREATE CONNECTION conn_jtdsmssql TO 
 'jdbc:jtds:sqlserver://<host>:1433;DatabaseName=<db name>;domain=AD;useNTLMv2=true;' 
 USER 'username' -- Windows Username 
 IDENTIFIED BY 'AD password here' --Windows password; 
```

Once the AD user/password are defined in the database connection (USER '' IDENTIFIED BY ''), they can be re-used as often as needed (as long as the credentials are valid). Please note that the passwords are masked in all SQL texts and logs. With this method, you can grant the connection only to the required users on Exasol side and it can be used to IMPORT data from SQL server.

Once your connection is created, you can test the connectivity by querying the SQL Server system catalog:

```sql
select * from  
 ( import from jdbc at conn_jtdsmssql statement 'select * from information_schema.tables'  );
```

If your connection is successful, you're ready to IMPORT/EXPORT data from SQL Server! If it isn't, please check your network settings and/or the settings of your SQL Server instance. Using the JTDS driver, one could import/export data using the following commands:

```sql
IMPORT INTO table1 FROM JDBC
 AT 'jdbc:jtds:sqlserver://dbserver;databaseName=testdb'  
 USER 'user1' 
 IDENTIFIED BY 'user1pw' TABLE table2;  
 
EXPORT table1 INTO JDBC
 AT 'jdbc:jtds:sqlserver://dbserver;databaseName=testdb'  
 USER 'user1' 
 IDENTIFIED BY 'user1pw' TABLE table2;  
  
IMPORT INTO table1 FROM JDBC
 AT conn_jtdsmssql TABLE table2;  
  
EXPORT table1 INTO JDBC
 AT conn_jtdsmssql TABLE table2;
```

### Microsoft SQL Server Driver

If you wish to use the official SQL Server driver, you need to install it first. You can download it from the [Microsoft Download Portal](https://docs.microsoft.com/en-us/sql/connect/jdbc/microsoft-jdbc-driver-for-sql-server). Driver installation procedure is explained in [Load data from Microsoft SQL Server / Add JDBC driver](https://docs.exasol.com/db/latest/loading_data/connect_sources/sql_server.htm#AddJDBCdriver).

From version 6.1 onwards, you will also need the system privileges IMPORT/EXPORT to be granted to your user (or one of it's roles). For example:

```sql
grant import,export to MY_USER;
```

#### Basic Syntax

Using **Microsoft's JDBC driver for SQL Server**, one could import/export data using the following commands:

```sql
IMPORT INTO table1  FROM JDBC
 AT 'jdbc:sqlserver://dbserver;databaseName=testdb'  
 USER 'user1' IDENTIFIED BY 'user1pw' TABLE table2;  
 
EXPORT table1 INTO JDBC
 AT 'jdbc:sqlserver://dbserver;databaseName=testdb'  
 USER 'user1' IDENTIFIED BY 'user1pw' TABLE table2; 
```

A **connection** could also be created and used:

```sql
CREATE CONNECTION conn_mssql  TO 
'jdbc:sqlserver://dbserver;databaseName=testdb'  
USER 'user1' IDENTIFIED BY 'user1pw';  

IMPORT INTO table1 FROM JDBC AT conn_mssql TABLE table2; 

EXPORT table1  INTO JDBC AT conn_mssql TABLE table2;
```

Once your connection is created, you can test the connectivity by querying the SQL Server system catalog like before:

```sql
select * from  
 ( import from jdbc at conn_mssql statement 'select * from information_schema.tables'  );
```

Please note, that usage of the newly created connection requires either a system privilege USE ANY CONNECTION or the connection has to be explicitly granted to the user. Connections are automatically granted to the creator, including the ADMIN OPTION.

## Additional References

* [Load data from Microsoft SQL Server](https://docs.exasol.com/loading_data/connect_databases/sql_server.htm)
* [JTDS Documentation](http://jtds.sourceforge.net/faq.html)
* [SQL Server JDBC Documentation](https://docs.microsoft.com/en-us/sql/connect/jdbc/microsoft-jdbc-driver-for-sql-server?view=sql-server-ver15)
* [IMPORT](https://docs.exasol.com/db/latest/sql/import.htm)
* [EXPORT](https://docs.exasol.com/db/latest/sql/export.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
