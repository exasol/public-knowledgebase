# The Exasol Logserver 
## Background

When looking into sessions on the database, you may notice a Session-ID 4 which never disappears. 

## Explanation

The [statistical system tables](https://docs.exasol.com/sql_references/metadata/statistical_system_table.htm) contain statistical usage data for the DBMS. This data is collected and written by a server process named LogServer (Session ID 4 in EXA_*_SESSIONS). The statistical data is buffered for a short period of time and written to the statistical system tables periodically. Statistical data can be flushed manually with the statement "FLUSH STATISTICS".  
It is not possible to kill or deactivate the process.

## Additional References

* [List of statistical tables](https://docs.exasol.com/sql_references/metadata/statistical_system_table.htm)
* [FLUSH STATISTICS syntax](https://docs.exasol.com/sql/flush_statistics.htm)
