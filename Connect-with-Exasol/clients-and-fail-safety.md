# Clients and Fail Safety 
## Background

This article explains some of the fail safety mechanisms that clients can perform. 

## Explanation

### Automatic reconnect

In case the database is not available or temporarily shut down, client connections to this database are terminated. The interfaces have the ability to automatically reconnect to the system.

* For the Exasol JDBC driver, ADO.NET driver, ODBC driver, Client SDK:  
The driver tries to get a new connection to the same session. If a transaction was open, the user gets an error like "Successfully reconnected, transaction was rolled back"

### Connection IP

All the active Exasol nodes can accept client connections. You can provide a connection string containing all possible hosts (including the reserve node) to the Exasol drivers.

* JDBC driver  
In the connection string, you can replace "Host:Port" with the list of all possible hosts and ports.
* ODBC driver  
The driver accepts the host list instead of the host parameter in the DSN configuration.
* ADO.NET driver  
The parameter "host" or "server" can contain a connection string similar to other interfaces (a node list or range and a port).

The connection string contains for a 4 +1 -node cluster for example following data:


```
192.168.0.2..6:8563 
```
Note that the connect time will increase if the host specified does not have an Exasol node running on them.

If the reconnect was not successful you can get one of the SQL states 40004, 40009, 40018, 40020. If it was successful and the transaction was rolled back you can get one of the SQL states: 40001, 40002, 40003, 40005, 40007, 40008, 40010, 40011, 40017, 40019. If the connection was completely lost you get the SQL state 08001.

## Additional References

* <https://docs.exasol.com/connect_exasol/drivers/odbc/using_odbc.htm>
* <https://docs.exasol.com/administration/on-premise/manage_software/manage_jdbc.htm>
* <https://docs.exasol.com/connect_exasol/drivers.htm>
* <https://docs.exasol.com/connect_exasol/drivers/ado_net.htm>
