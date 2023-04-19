# EXAloader 3rd party JDBC requirements for IMPORT and EXPORT command 
## Background

 In order for the Exasol Database to use a JDBC Driver in IMPORT or EXPORT commands, the JDBC Driver must support the following methods.

If the JDBC driver does not, you might get an error message like:


```markup
[42636] ETL-5402: JDBC-Client-Error: Exception while disconnecting: Method not supported (Session: 1484043015261801495) 
```
## Explanation

When IMPORTing data from JDBC sources, EXAloader requires that the following methods are implemented by the JDBC driver.

* java.sql.Connection
	+ void setAutoCommit(boolean autoCommit)
	+ Statement createStatement()
	+ PreparedStatement prepareStatement(String sql)
	+ void rollback()
	+ void close()
* java.sql.Statement
	+ void setFetchSize(int rows)
	+ ResultSet executeQuery(String sql)
	+ void close()
* java.sql.PreparedStatement
	+ ResultSetMetaData getMetaData()
* java.sql.ResultSetMetaData
	+ int getColumnCount()
	+ int getColumnType(int column)
	+ String getColumnName(int column)
* java.sql.ResultSet
	+ ResultSetMetaData getMetaData()
	+ boolean next()
	+ long getLong(int columnIndex)
	+ double getDouble(int columnIndex)
	+ BigDecimal getBigDecimal(int columnIndex)
	+ String getString(int columnIndex)
	+ Date getDate(int columnIndex)
	+ Timestamp getTimestamp(int columnIndex)
	+ Clob getClob(int columnIndex)
	+ boolean getBoolean(int columnIndex)
	+ boolean wasNull()
	+ void close()

When EXPORTing data into JDBC sources, EXAloader requires that the following methods are implemented by the JDBC driver.

* java.sql.Connection
	+ void setAutoCommit(boolean autoCommit)
	+ Statement createStatement()
	+ PreparedStatement prepareStatement(String sql)
	+ void rollback()
	+ void commit()
	+ void close()
* java.sql.Statement
	+ int[] executeBatch()
	+ boolean execute(String sql)
	+ void close()
* java.sql.PreparedStatement
	+ ParameterMetaData getParameterMetaData()
	+ void setLong(int parameterIndex, long x)
	+ void setDouble(int parameterIndex, double x)
	+ void setString(int parameterIndex, String x)
	+ void setDate(int parameterIndex, Date x)
	+ void setTimestamp(int parameterIndex, Timestamp x)
	+ void setBoolean(int parameterIndex, boolean x)
	+ void setNull(int parameterIndex, int sqlType)
	+ void addBatch()
* java.sql.ParameterMetaData
	+ int getParameterCount()
	+ int getParameterType(int param)

In order to use a JDBC driver that doesn't support all required functions, you can write a wrapper for it. In that wrapper, you can e.g. suppress Exceptions or enhance the functionality of the JDBC driver in order to get it to work.

## Additional References

* [JDBC Driver Installation](https://docs.exasol.com/loading_data/connect_databases/import_data_using_jdbc.htm)
* [IMPORT](https://docs.exasol.com/sql/import.htm)
* [EXPORT](https://docs.exasol.com/sql/export.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 