# How to Troubleshoot a Tableau Query Error

## Question
If I try to access a table from Tableau (ODBC) I get the following error:  
[EXASOL][EXASolution driver]'.' character is not allowed within quoted identifiers [line 16, column 32] (Session: 1707907005981458432)
Fehlercode: 1E953F46

I do not see any quoted column with a "."  in it. How can this issue be solved?  

## Answer
Check:
> select * from exa_dba_audit_sql where session_id=1707907005981458432 and success=false;

This should tell you what Tableau is up to and give you an indication what you´re dealing with ( see column SQL_TEXT ).

Prerequisite: Auditing is enabled on your database (as it should be).