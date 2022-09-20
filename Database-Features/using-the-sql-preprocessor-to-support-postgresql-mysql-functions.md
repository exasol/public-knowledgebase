# Using the SQL preprocessor to support PostgreSQL/MySQL functions (e.g. DATE ) 
## Background

Some functions from other databases are not supported by Exasol. But with the powerful SQL preprocessor framework, you can easily extend the SQL language of Exasol.

## Explanation

The following simple example shows how the DATE function from postgreSQL/ MySQL is mapped to TO_DATE:


```"code-sql"
--/  
CREATE OR REPLACE LUA SCRIPT "POSTGRES2EXA" () RETURNS ROWCOUNT AS  import('TRANSFORMATIONS', 'TRANSFORMATIONS')  -- get SQL text sqltext = sqlparsing.getsqltext()  --Perform transformations newsqltext = TRANSFORMATIONS.transformDatetoDate(sqltext)  -- set thew new SQL text sqlparsing.setsqltext(newsqltext)  / --/ CREATE OR REPLACE LUA SCRIPT "TRANSFORMATIONS" () RETURNS ROWCOUNT AS  function transformDatetoDate(sqltext)     while(true) do     local tokens = sqlparsing.tokenize(sqltext)        found = sqlparsing.find(tokens, 1, true, false, sqlparsing.iswhitespaceorcomment,                              'DATE', '(')        if (found==nil) then       break;     end      local ifEnd = sqlparsing.find(tokens, found[2],true, true, sqlparsing.iswhitespaceorcomment, ')')      if (ifEnd==nil) then         error("date function not properly ended")     end          sqltext = table.concat(tokens, '', 1, found[1]-1)..'TO_DATE ('..table.concat(tokens, '', found[2]+1)    end    return sqltext  end  / 
```
To activate the preprocessor script for the current session, please use the following command:


```"code-sql"
alter session set SQL_PREPROCESSOR_SCRIPT = <MYSCHEMA>.POSTGRES2EXA;
```
## Additional References

* [Preprocessor Scripts Documentation](https://docs.exasol.com/database_concepts/sql_preprocessor.htm)
* [List of functions in Exasol](https://docs.exasol.com/sql_references/functions/all_functions.htm)
