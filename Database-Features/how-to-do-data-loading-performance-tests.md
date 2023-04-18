# How to do data loading performance tests? 
## Background

## Load performance tests

### General:

One of EXASOL’s main differentiation criteria is its unprecedented loading performance, which is typically far superior to other DWHs. In order to achieve maximum performance, some fundamentals and best practices should be taken into consideration.

EXASOL is a shared-nothing database, running on multiple nodes. Ideally, those nodes’ individual capabilities to open connections to remote sources are best utilized by a “pull” approach on data loading: EXASOLs native bulk loader (“EXAloader”) makes this easy to do. It is triggered by a straight forward SQL command and hides most complexity arising from parallel loading from the user. For the complete syntax see the EXASOL manual section 2.2.2 ‘IMPORT’ . 


```"code
IMPORT INTO table_1 FROM CSV AT 'http://192.168.1.1:8080/' 
USER 'agent_007' IDENTIFIED BY 'secret' FILE 'tab1_part1.csv'; 
```
Some ETL tools, such. as e.g. Talend, are able to employ EXAloader. An ETL tool that uses a standard connection (ODBC / JDBC) will not be able to manage parallelism (alone for the fact that it is usually unaware of the cluster resources), results will therefore always be suboptimal.

## Explanation

## Sources:

Sources to load from are:

* **Import from another EXASOL DB:** Parallelism fully automated; optimal performance.
* **CSV / FBV via HTTP/HTTPS or FTP / FTPS:** Often preferable, due to the performance of HTTP/FTP servers and their capability to serve multiple connections, as well as the simplicity of the dataset (effortless serving).
* **CSV / FBV from a local client via EXAplus**: A local dataset is also transferred via HTTP, but in contrast to the option above, the open connection is used for the data transfer – to avoid problems due to NAT/firewall restrictions. This limits the amount of parallelism and will, therefore, be less performant than an import from a server.
* **JDBC from other data sources:** The protocol introduces some overhead. However, it is possible to define multiple datasets within one IMPORT statement: 
```"code
IMPORT INTO table_4 FROM JDBC 
AT 'jdbc:exa:192.168.6.11..14:8563' 
USER 'agent_008' IDENTIFIED BY 'secret' 
STATEMENT ' SELECT * FROM orders WHERE order_state=''OK'' ' 
STATEMENT ‘SELECT * from tbl2’ TABLE customers; 
```
* **Import from an Oracle DB via native ORA interface:** The performance of the protocol is preferable to JDBC. Loading is conducted in parallel if the table is partitioned in the Oracle Database.

## Monitoring and performance measurement:

### System tables:

In general, system tables should be queried with AUTOCOMMIT ON to avoid difficulties caused by readlocks on the objects whose metadata is queried.

* EXA_(USER/ALL/DBA)_SESSIONS shows the number of rows already inserted by the currently running IMPORT statement.
* EXA_MONITOR_LAST_DAY gives an indication on CPU / HDD / NET traffic
* EXA_DB_SIZE_LAST_DAY provides info on data growth inside EXASOL
* EXA_(USER/ALL/DBA)_OBJECT_SIZES shows the size of objects
* EXA_DBA_AUDIT_SQL shows the import command, duration, and several other attributes
* EXA_(USER/ALL/DBA)_SQL_LAST_DAY shows the command classes, duration and several other attributes (but not the statement text)

### Time measurement

EXAplus can return timings of jobs:


```"code
timing start; 
IMPORT FROM ...; 
timing stop; 
```
Alternatively you can lookup the duration of the import runs from the system tables (EXA_DBA_AUDIT_SQL or EXA_*_SQL_LAST_DAY). This makes it easy to visualize it with a standard BI tool.

## Best practices:

* Before the Import, the destination table must be defined in EXASOL. For an automated migration of a remote database schema EXASOL provides a set of **[database migration scripts on Github](https://github.com/EXASOL/database-migration)**.
* Imports are faster without **distribution keys** present (however setting these later would need time for reorganization), and without **table constraints** defined or with constraint checking disabled.
* Optimal **compression** of a table may be achieved by explicitly triggering a RECOMPRESS TABLE tbl; (see EXASOL manual sec. 2.2.6 'RECOMPRESS').
* It is possible to do the whole job within one IMPORT statement; EXAloader will utilize resources optimally. However, also the import runs inside an **ACID transaction** which would be rolled back entirely on any error. It may, therefore, be advisable to do larger jobs in separate transactions (sequentially or in parallel e.g. by opening several EXAplus instances).
* Often the dataset is not entirely known. To avoid **errors causing the import to abort** it may be advisable to define a REJECT LIMIT () combined with an ERROR TABLE or log file. See for details EXASOL manual section 2.2.2 ‘IMPORT’ -> ‘error_clause’ in the notes paragraph. Example: 
```"code
IMPORT INTO table_3 (col1, col2, col4) FROM ORA 
AT my_oracle USER 'agent_008' IDENTIFIED BY 'secret' 
STATEMENT ' SELECT * FROM orders WHERE order_state=''OK'' ' 
ERRORS INTO error_table (CURRENT_TIMESTAMP) REJECT LIMIT 10; 
```

## Additional References

<https://docs.exasol.com/sql/import.htm>

<https://docs.exasol.com/sql/export.htm>

<https://docs.exasol.com/loading_data/csv_fbv_file_types.htm>

<https://docs.exasol.com/loading_data/load_data_from_externalsources.htm>

