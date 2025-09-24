# Not able to connect to Oracle DB after upgrading to v8

## Problem

After upgrading to v8, customer is not able to connect to Oracle DB with short host name. Connection can be established with FQDN and IP adrress but not with short host name.

Connection details:

```text
create connection ORA_TEST to '(DESCRIPTION = (ADDRESS_LIST = (ADDRESS = (COMMUNITY = tcp.world)(PROTOCOL = TCP)(Host = DB-ENDUR)(Port = 1520)) (ADDRESS = (COMMUNITY = tcp.world)(PROTOCOL = TCP)(Host = DB-ENDUR)(Port = 1521)) (LOAD_BALANCE = off) (FAILOVER = on) ) (CONNECT_DATA = (SERVICE_NAME = ENDUR_TEST.VERBUND.CO.AT) ) )'
```

Query:

```text
[IMPORT INTO T_00_STAGING_TABLES FROM ORA AT ORA_TEST USER 'test' IDENTIFIED BY '???'  STATEMENT 'WITH q1 as (SELECT ID, ORACLE_TABLE_SCHEMA, ORACLE_TABLE_NAME, EXASOL_TABLE_SCHEMA, EXASOL_TABLE_NAME, EXASOL_TO_ORACLE_CONNECTION, FL_ACTIVE, FL_ABRECHNUNG, EXASOL_TO_ORACLE_CONNECTION_2, SQL_WHERE, SQL_WHERE2 FROM T_00_STAGING_TABLES WHERE ''TESTSYSTEM'' = ''TESTSYSTEM'' AND DB_TYPE = ''TESTSYSTEM'' AND ''PS2'' = SCRIPT_SCHEMA) SELECT ID, ORACLE_TABLE_SCHEMA, ORACLE_TABLE_NAME, EXASOL_TABLE_SCHEMA, EXASOL_TABLE_NAME, EXASOL_TO_ORACLE_CONNECTION,  FL_ACTIVE, FL_ABRECHNUNG, EXASOL_TO_ORACLE_CONNECTION_2, SQL_WHERE, SQL_WHERE2 FROM T_00_STAGING_TABLES WHERE DB_TYPE = ''TEST'' AND ID NOT IN (SELECT ID FROM q1) UNION ALL SELECT ID, ORACLE_TABLE_SCHEMA, ORACLE_TABLE_NAME, EXASOL_TABLE_SCHEMA, EXASOL_TABLE_NAME, EXASOL_TO_ORACLE_CONNECTION, FL_ACTIVE, FL_ABRECHNUNG, EXASOL_TO_ORACLE_CONNECTION_2, SQL_WHERE, SQL_WHERE2 FROM Q1'] 
```

Error:

```text
Oracle tool failed with error code '12545' and message 'ORA-12545: Connect failed because target host or object does not exist
```

## Solution

After upgrading to v8, search domain needs to be set as described below for short host name to work.

About Search domain :
A Linux search domain is a domain name, or a list of domains, that the operating system automatically appends to a short hostname (like "server1") when you try to resolve it to an IP address. This process is part of DNS resolution and allows you to access local network devices using only their simple hostnames instead of their full, fully qualified domain names (FQDNs) (e.g., server1.example.com). For example, if your search domain is example.com and you type forums, your system will search for forums.example.com.

To set up the "search" domain one should use the following command inside the container:

```shell
confd_client general_settings changes: '{Global: {SearchDomains: power.inet}}'
```

After that, the exasol service needs to be restarted, to safely do it, please follow below steps:

1. Stop the database by using below command

    ```shell
    confd_client db_stop db_name: <DB-NAME>
    ```

2. Exit the container and run the command on all nodes

    ```shell
    systemctl stop c4_cloud_command
    systemctl start c4_cloud_command
    ```

   In case of rootless installation, the commands would be these:

    ```shell
    systemctl --user stop c4_cloud_command
    systemctl --user start c4_cloud_command
    ```

3. If the database is not running, start it now using the ConfD job db_start:

    ```shell
    confd_client db_start db_name: <DB-NAME>
    ```

### Additional references

* [Documentation of ConfDSettings](https://docs.exasol.com/db/latest/confd/jobs/general_settings.htm)
* [Documentation of Stop and Start Nodes](https://docs.exasol.com/db/latest/administration/on-premise/nodes/stop_start_nodes.htm)
