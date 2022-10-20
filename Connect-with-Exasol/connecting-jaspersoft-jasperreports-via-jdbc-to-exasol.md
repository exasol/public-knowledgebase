# Connecting JasperSoft JasperReports via JDBC to Exasol
## How to connect JasperSoftReports via JDBC to Exasol

## Step 1

Use the appropriate Exasol JDBC Driver.

## Step 2

In JasperReports, choose "Oracle" as database dialect when connecting via generic JDBC.

## Step 3

Please verify that the following parameters are NOT set to the following values (especially in that combination):


```"noformat
defaultAutoCommit = false rollbackOnReturn = true 
```
## Additional Notes

If both parameters are set like above, it is very likely that only rollbacks are sent after SELECTs (and never commits). Thus, indices that are created by these SELECTs automatically are never saved to the database and cannot be reused by other queries (see <https://community.exasol.com/t5/database-features/indexes/ta-p/1512>).

## Additional References

See also the following page for further information on these parameters:  
<https://tomcat.apache.org/tomcat-8.0-doc/jdbc-pool.html>

## Additional References

<https://community.exasol.com/t5/database-features/correct-settings-for-odbc-driver/ta-p/1440>

<https://community.exasol.com/t5/database-features/check-connectibility-of-exasolution-to-external-network-services/ta-p/1433>

<https://community.exasol.com/t5/connect-with-exasol/jdbc-import-export-create-and-receive-jdbc-logs/ta-p/1050>

