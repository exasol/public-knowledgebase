# EXASOL Database Network Port Usage Summary 
## Background

The tables below list the **default** ports of network services and DBMSs with which the EXASOL database may communicate.

## Notes

* Many of the following protocols and DBMSs can be manually configured to use different ports.
* The File Transfer Protocol (FTP) data connections require additional ports to be available (depending on the transfer mode).

## Network port assignments

### Incoming Connections



|  |  |  |  |  |
| --- | --- | --- | --- | --- |
| **Protocol** | **Port** | **Source** | **Destination** | **Description** |
| TCP | 8563 | EXASOL Client | EXASOL database nodes | EXASOL server port |
| TCP | Range from 20000 to 21000 | EXASOL database nodes (source) | EXASOL database nodes (target) | EXASOL sub connection ports (for EXA-to-EXA loading) |

### Outgoing Connections



|  |  |  |  |  |
| --- | --- | --- | --- | --- |
| **Protocol** | **Port** | **Source** | **Destination** | **Description** |
| TCP | 8563 | EXASOL database nodes | EXASOL database client | EXASOL database client connection port |
| TCP | Range from 20000 to 21000 | EXASOL database nodes (source) | EXASOL database nodes (target) | EXASOL subconnection ports (for EXA-to-EXA loading) |
| TCP | 20 | EXASOL database nodes | FTP server | FTP data port for IMPORT/EXPORT |
| TCP | 21 | EXASOL database nodes | FTP server | FTP command port for IMPORT/EXPORT |
| TCP | 22 | EXASOL database nodes | SFTP server | SFTP port for IMPORT/EXPORT |
| TCP | 80 | EXASOL database nodes | HTTP server | HTTP port for IMPORT/EXPORT |
| TCP | 443 | EXASOL database nodes | HTTPS server | HTTPS port for IMPORT/EXPORT |
| TCP | 990 | EXASOL database nodes | FTPS server | FTPS port for IMPORT/EXPORT |
| TCP | 389 | EXASOL nodes | LDAP server | LDAP port |
| TCP | 636 | EXASOL nodes | LDAPS server | LDAPS port |
| TCP | 1521 | EXASOL database nodes | Oracle database | Oracle server port (JDBC/ORA connection) |
| TCP | 1433 | EXASOL database nodes | SQL Server database | SQL Server server port (JDBC connection) |
| TCP | 3306 | EXASOL database nodes | MySQL database | MySQL server port (JDBC connection) |
| TCP | 50000 | EXASOL database nodes | DB2 database | DB2 server port (JDBC connection) |
| TCP | 5432 | EXASOL database nodes | PostgreSQL database | PostgreSQL server port (JDBC connection) |
| TCP | 5000 | EXASOL database nodes | Sybase ASE database | Sybase ASE server port (JDBC connection) |

## Additional References

<https://docs.exasol.com/administration/on-premise/installation/prepareenvironment/cluster_networking_infrastructure.htm?Highlight=network>

