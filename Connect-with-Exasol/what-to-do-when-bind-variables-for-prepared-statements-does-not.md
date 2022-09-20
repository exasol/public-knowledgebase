# What to do when Bind Variables for Prepared Statements does not work 
## Problem

Bind Variables in prepared statements for executing a script does not work.

## Diagnosis

When the user executes this statement *con.prepareStatement( "EXECUTE SCRIPT LUASCRIPT ?" )  in a java programm ,* the user gets an error like this:


```
java.sql.SQLSyntaxErrorException: syntax error, unexpected '?', expecting END_OF_INPUT_ or ';' [line 1, column 26] (Session: 1681284472046092288)  
at com.exasol.jdbc.ExceptionFactory.createSQLException(ExceptionFactory.java:39)  
...
```
## Explanation

We do not support Prepared Parameters in EXECUTE SCRIPT statements. 

## Recommendation

As a workaround, to prevent SQL injection, you can insert the parameter value into a temporary table and use that value in the script.

Example:

Assume, that we have a script that creates a table based upon the parameter. 


```
--/  
CREATE or REPLACE lua SCRIPT test.my_script_old (table_name) AS  
query([[create table ::t (a int )]], {t=table_name})  
/  
  

```
We have to rewrite our example script:

It now reads the values from a table test.temp


```
CREATE or REPLACE lua SCRIPT test.my_script_new () AS  
  local success, res = pquery([[SELECT name FROM test.temp]])  
  table_name = res[1][1]  
  query([[create table ::t (a int )]], {t=table_name})  
/
```
So, we can use it now in our java class as follow:


```
// create tempory table  
stmt = con.prepareStatement( "create or replace table test.temp (name varchar(100))" );  
stmt.execute();  
  
// insert the needed parameter  
stmt = con.prepareStatement( "insert into test.temp values (?)" );  
stmt.setString(1, "test.testtable");  
stmt.execute();  
  
// execute the script  
stmt = con.prepareStatement( "execute script test.my_script()" );  
stmt.execute();  
  
// drop the temporary table  
stmt = con.prepareStatement( "drop table test.temp" );  
stmt.execute();  
  
// commit  
con.commit();
```
## Additional References

* <https://docs.exasol.com/database_concepts/scripting/db_interaction.htm>
* <https://docs.exasol.com/connect_exasol/drivers/jdbc.htm>
