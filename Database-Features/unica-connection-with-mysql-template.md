# Unica: Connection with MySQL template 
## Problem

IBM Unica Campaign with MySQL template

[EXASOL][EXASolution driver]syntax error, unexpected '<'[line x, column y] of [EXASOL][EXASolution driver]function or script ADDDATE not found[line x, column y]

 Unica generates SQL statements that are not identically supported by EXASolution.

## Solution

Create a pre-processor script that adjusts the SQL statements to appropriate ones.


```"code-java"
CREATE OR REPLACE LUA SCRIPT DATAMART.PPSCRIPT_MYSQL RETURNS ROWCOUNT AS function unicaproc(sqltext)   local tokens = sqlparsing.tokenize(sqltext)   for i=1,#tokens do     if string.upper(tokens[i]) == 'ADDDATE' then            tokens[i] = 'ADD_DAYS'     end     if tokens[i] == '<' and string.upper(tokens[i+1]) == 'CURRENT_DATE' then       tokens[i] = ''     end     if string.upper(tokens[i]) == 'UNSUPPORTED' and tokens[i+1] == '>' then       tokens[i] = ''       tokens[i+1] = ''     end   end   return table.concat(tokens) end / 
```
Activate this preprocessor script for all Unica session or system wide:


```"code-java"
ALTER [SESSION|SYSTEM] SET sql_preprocessor_script=DATAMART.PPSCRIPT_MYSQL;
```
