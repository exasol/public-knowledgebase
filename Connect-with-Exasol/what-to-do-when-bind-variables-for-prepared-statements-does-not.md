# What to do when Bind Variables for Prepared Statements do not work 
## Problem

Bind Variables in prepared statements for executing a script do not work.

## Diagnosis

When the user executes this statement `con.prepareStatement( "EXECUTE SCRIPT LUASCRIPT ?" )` in a java program, the user gets an error like this:


```
java.sql.SQLSyntaxErrorException: syntax error, unexpected '?', 
expecting END_OF_INPUT_ or ';' [line 1, column 26] (Session: 1681284472046092288)  
at com.exasol.jdbc.ExceptionFactory.createSQLException(ExceptionFactory.java:39)  
...
```
## Explanation

We do not support Prepared Parameters in EXECUTE SCRIPT statements. 

## Recommendation

As a workaround, to prevent SQL injection, you can insert the parameter value into a temporary table and use that value in the script.

Example:

Assume, that we have a script that creates a table based upon the parameter. 


```lua
--/  
CREATE or REPLACE lua SCRIPT test.my_script_old (table_name) AS  
query([[create table ::t (a int )]], {t=table_name})  
/  
  

```
We have to rewrite our example script:

It now reads the values from a table test.temp


```lua
CREATE or REPLACE lua SCRIPT test.my_script_new () AS  
  local success, res = pquery([[SELECT name FROM test.temp]])  
  table_name = res[1].NAME
  query([[create table ::t (a int )]], {t=table_name})  
/
```

So, we can use it now in our java class as follow:


```java
// create temporary table  
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

* [Database Interaction](https://docs.exasol.com/database_concepts/scripting/db_interaction.htm)
* [JDBC Driver](https://docs.exasol.com/connect_exasol/drivers/jdbc.htm)

## Downloads

* [Bind_variables_not_working_example.java](https://github.com/exasol/public-knowledgebase/blob/main/Connect-with-Exasol/attachments/Bind_variables_not_working_example.java)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 