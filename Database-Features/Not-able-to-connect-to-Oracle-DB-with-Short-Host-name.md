# Not able to connect to Oracle DB with Short Host Name

## Problem

Customer is not able to connect to Oracle DB with short host name.Connection can be established with FQDN and IP address but not with short host name.
Below is example of connection detail and query which failed with error.

Connection detail:

```sql
create connection my_oracle to '(DESCRIPTION = (ADDRESS_LIST = (ADDRESS = (COMMUNITY = tcp.test)(PROTOCOL = TCP)(Host = DB-TEST)(Port = 1520)) (ADDRESS = (COMMUNITY = test.test)(PROTOCOL = TCP)(Host = DB-TEST)(Port = 1521)) (LOAD_BALANCE = off) (FAILOVER = on) ) (CONNECT_DATA = (SERVICE_NAME = orautf8) ) )'
```

Query:

```sql
IMPORT INTO my_table (col1, col2, col4) 
FROM ORA
AT my_oracle
USER 'my_user' IDENTIFIED BY 'my_secret'
STATEMENT ' SELECT * FROM orders WHERE order_state=''OK'' '
```

Error:

```text
Oracle tool failed with error code '12545' and message 'ORA-12545: Connect failed because target host or object does not exist
```

## Solution

For the short host name to work, search domain needs to be configured as described below.If search domain was configured in v7, it should also be configured in v8 after upgrade to v8.

About Search domain:
A Linux search domain is a domain name, or a list of domains, that the operating system automatically appends to a short hostname (like "server1") when you try to resolve it to an IP address. This process is part of DNS resolution and allows you to access local network devices using only their simple hostnames instead of their fully qualified domain names (FQDNs) (e.g., server1.example.com). For example, if your search domain is example.com and you type forums, your system will search for forums.example.com.

To set up the "search" domain "power.inet" (just an example) one should use the following command inside the container:

```shell
confd_client general_settings changes: '{Global: {SearchDomains: power.inet}}'
```

After that, the exasol service needs to be restarted, To safely do it, please follow below steps:

1. Stop the database by using below command

    ```shell
    confd_client db_stop db_name: <DB-NAME>
    ```

2. Exit the container and run the command on all nodes

    ```shell
    systemctl stop c4_cloud_command
    systemctl start c4_cloud_command
    ```

   By default DB automatically starts when c4 services start. If it doesn't, start it using the ConfD job db_start:

    ```shell
    confd_client db_start db_name: <DB-NAME>
    ```

   In case of rootless installation, the commands would be these:

    ```shell
    systemctl --user stop c4_cloud_command
    systemctl --user start c4_cloud_command
    ```

### Additional references

* [Documentation of ConfD job "general_settings"](https://docs.exasol.com/db/latest/confd/jobs/general_settings.htm)
* [Documentation of Stop and Start Nodes](https://docs.exasol.com/db/latest/administration/on-premise/nodes/stop_start_nodes.htm)
