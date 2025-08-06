# EXA_STATISTICS 
## Background

Each Exasol database includes two out-of-the-box schemas: SYS and EXA_STATISTICS. It is not possible to change these schemas manually, and the information visible in some system tables depend on the object and system privileges the user is assigned. It is also possible to grant access to every table in these schemas by granting the SELECT ANY DICTIONARY privilege to a user or role. 

## General Information

Exasol offers numerous statistical system tables containing data about the usage and the status of the DBMS. These system tables are located in the "EXA_STATISTICS" schema but are automatically integrated into the current namespace. This means that if an object with the same name does not exist in the current schema, they can be queried without the schema name, "EXA_STATISTICS". Otherwise, the system tables can be accessed via the respective schema-qualified name, EXA_STATISTICS.<table_name> (e.g. "SELECT * FROM EXA_STATISTICS.EXA_MONITOR_LAST_DAY").

All timestamps of historical statistics are stored in the current server time zone (DBTIMEZONE).

Statistics are updated periodically by a Server Process named "SQL LOGSERVER" ([more info here](https://exasol.my.site.com/s/article/The-Exasol-Logserver)). To manually flush statistical data, the command "[FLUSH STATISTICS](https://docs.exasol.com/db/latest/sql/flush_statistics.htm)" is available. All tables are subject to the [transaction system](https://docs.exasol.com/database_concepts/transaction_management.htm). Therefore it might be necessary to open a new transaction to see the up-to-date data.  
Statistical system tables, except those tables that are critical to security (e.g. auditing data), can be accessed by all users.

## Statistical data classes

In general there are four different classes of statistical data:

* Monitoring data (EXA_MONITOR_*), e.g. CPU usage, TEMP_DB_RAM, HDD_READ, etc., for the entire database
* DB size data (EXA_DB_SIZE_*), e.g. compressed database size
* Query data (EXA_SQL_*), e.g. average query duration
* Usage data (EXA_USAGE_*), e.g. concurrent queries

For each class there are four shapes:

* Detailed data for the last 24 hours (*_LAST_DAY)
* Aggregated data (*_HOURLY, *_DAILY, *_MONTHLY)

Therefore there are a total of 16 tables. Examples:

* EXA_MONITOR_LAST_DAY
* EXA_DB_SIZE_HOURLY
* EXA_SQL_DAILY
* EXA_USAGE_MONTHLY

## Additional statistical system tables

### Auditing data

If Auditing is enabled for the database, the tables EXA_DBA_AUDIT_SESSIONS and EXA_DBA_AUDIT_SQL are used to trace all sessions/queries connected to/sent to the database.  
Those tables can be accessed by users having the "SELECT ANY DICTIONARY" system privilege.  
Auditing data can be dropped by the "[TRUNCATE AUDIT LOGS](https://docs.exasol.com/sql/truncate_audit_logs.htm)" statement.

### Profiling data

Profiling can be used to analyze queries in detail. Therefore the tables EXA_DBA_PROFILE_LAST_DAY and EXA_USER_PROFILE_LAST_DAY can be used. See [here](https://docs.exasol.com/database_concepts/profiling.htm) for further information on profiling. This information is only available for the previous 24 hours.

### Transaction conflicts

The table EXA_DBA_TRANSACTION_CONFLICTS lists all transaction conflicts that occurred. This table can be accessed by users having the "SELECT ANY DICTIONARY" system privilege.  
The table EXA_USER_TRANSACTION_CONFLICTS_LAST_DAY lists all transaction conflicts that occurred within sessions created by the current user for the last day.  
Both tables can be truncated with the "TRUNCATE AUDIT LOGS" statement.

### System events

The table EXA_SYSTEM_EVENTS contains system events, such as:

* STARTUP, SHUTDOWN, RESTART
* BACKUP_START, BACKUP_END
* RESTORE_START, RESTORE_END
* FAILSAFETY, RECOVERY_START, RECOVERY_END

## Example

Determining the overall average compression ratio, average raw database size and average compressed database size on monthly basis:


```sql
SELECT RAW_OBJECT_SIZE_AVG/NULLIFZERO(MEM_OBJECT_SIZE_AVG) AS COMPRESSION_RATIO,        
 RAW_OBJECT_SIZE_AVG,        
 MEM_OBJECT_SIZE_AVG FROM EXA_DB_SIZE_MONTHLY;
```
## Additional References

* [The Exasol Logserver](https://exasol.my.site.com/s/article/The-Exasol-Logserver)
* [Statistical Tables](https://docs.exasol.com/sql_references/metadata/statistical_system_table.htm)
* [Transaction Management](https://docs.exasol.com/database_concepts/transaction_management.htm)
* [Profiling](https://docs.exasol.com/database_concepts/profiling.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 
