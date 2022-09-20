# Problems with special characters (UTF-8) in php using unixODBC 
## Problem

* Strings read from EXA using PHP via ODBC are truncated.
* PHP throws truncation errors while reading Strings from EXA via ODBC
* Unicode Strings cannot be displayed or are truncated

## Diagnosis

You are using PHP on NIX and the PHP is not working properly when using special characters. PHP reads the column attribute displaySize and uses it as octetLength while allocating SQLFetch and SQLGetData buffers. For Unicode strings this buffers may be too small. You can see this in the verbose EXA ODBC logfile (Logmode=verbose).

## Solution

You can use the EXA ODBC connection string attribute CHARACTERDISPLAYSIZE=4 to set a display size of 4 for each character in strings, so if displaySize is read by PHP it will get displaySize*CHARACTERDISPLAYSIZE and it will allocate larger buffers.

## Additional References

* [Exasol ODBC Documentation](https://docs.exasol.com/connect_exasol/drivers/odbc/using_odbc.htm)
