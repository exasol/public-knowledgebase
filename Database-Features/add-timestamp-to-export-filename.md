# How to Add Timestamp to Exported Filename

## Question
Is there a simple solution to manipulate string parameter when calling Export to csv function in such manner it automatically adds timestamp to filename? 

Here's an example of what I am trying to get:
```
EXPORT <table_name> 
INTO LOCAL CSV FILE 'C:\exportfile_<current_timestamp>.csv'
```
## Answer
You are right, this feature is not supported with the "INTO LOCAL CSV FILE" condition.

https://docs.exasol.com/db/latest/sql/export.htm

If you want to export the data to a local file system, then there is only the possibility via JDBC driver or EXAplus.
Spontaneously come to mind the solution via a bash script.
Something like that...
```
#!/bin/bash  

host="192.168.56.101"  
port="8563"  
user="sys"  
pwd="exasol"  

echo -e "EXPORT INTO LOCAL CSV FILE"  
timestamp=`date +%s`  
./exaplus -c $host:$port -u $user -p $pwd -sql "EXPORT <SCHEMA>.<TABLE> INTO LOCAL CSV FILE '/tmp/exportfile_$timestamp.csv';
```