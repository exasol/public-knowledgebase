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

If both parameters are set like above, it is very likely that only rollbacks are sent after SELECTs (and never commits). Thus, indices that are created by these SELECTs automatically are never saved to the database and cannot be reused by other queries (see <https://exasol.my.site.com/s/article/Indexes>).

## Additional References

See also the following page for further information on these parameters:  
<https://tomcat.apache.org/tomcat-8.0-doc/jdbc-pool.html>

## Additional References

<https://exasol.my.site.com/s/article/Correct-settings-for-ODBC-driver>

<https://exasol.my.site.com/s/article/Check-connectibility-of-EXASolution-to-external-network-services>

<https://exasol.my.site.com/s/article/JDBC-IMPORT-EXPORT-Create-and-receive-JDBC-logs>

