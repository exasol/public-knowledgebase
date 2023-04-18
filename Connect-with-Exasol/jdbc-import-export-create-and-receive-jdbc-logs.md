# JDBC IMPORT/EXPORT: Create and receive JDBC logs 
## Background

If you run IMPORT/EXPORT commands with another DBMS, sometimes you may need to generate JDBC logs to debug why the statement is not working. This is especially true if you do not receive any error message, and the command "hangs". This article specifically describes how to create these logs when connecting to an external source, like SQL Server, Oracle, or any other JDBC source. 

## Prerequisites

A JDBC connection must be created to your source.   

## How to create JDBC Logs

## Step 1: View Documentation

The JDBC Connection string needs to be edited to enable JDBC logging. The exact parameters and connection string to be used is not related to Exasol, but actually is determined by the source. So if you are connecting to an Oracle database, you must look at Oracle's documentation to find the correct connection string to use which enables JDBC logging. If you are connecting to an Exasol Database, you can look at [our documentation](https://docs.exasol.com/connect_exasol/drivers/jdbc.htm).

## Step 2: Edit Connection String

Edit your JDBC Connection string (based on step 1) and use this path and filename when choosing your filename:

/var/tmp/&lt;identifier&gt;-jdbc.log

For example :  
You can set this parameter ***debug=1*** in the connection string of your JDBC driver.  
*jdbc:exa:192.168.6.11..14:8563;debug=1;logdir=/tmp/my folder/;schema=sys*

It is useful to use a unique identifier for every IMPORT/EXPORT job so that we know which file to look at. 

## Step 3

You have to contact EXASOL support to receive the JDBC logs. For this we need the destination and filename of the logfile.

## Additional Notes

Remember, the parameters that you need to change to enable JDBC logging depend on which source you are connecting to. If your source does not support JDBC logging, then this article is also not applicable. 

## Additional References

* [Loading Data Documentation](https://docs.exasol.com/loading_data/load_data_from_externalsources.htm)
* [CREATE CONNECTION](https://docs.exasol.com/sql/create_connection.htm)
