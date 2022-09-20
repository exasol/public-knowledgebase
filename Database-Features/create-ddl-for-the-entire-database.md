# Create DDL for the entire Database 
## Background

EXAplus and many other database browsers provide the functionality to create the DDL for the database.  
This solution is a Lua script to do the same task and generates the DDL for each database object based on the system tables.

## Prerequisites

There are parameters to influence the output style. Documentation on the parameters and some known restrictions can be found at the beginning of the script. The latest release covers all supported database versions. Please see the header of the script for more information on what is supported and the current limitations.

PARAMETERS:   
-



|  |  |  |
| --- | --- | --- |
| **Parameter** | **Data Type** | **Meaning** |
| add_user_structure | Boolean | If true then DDL for adding roles and users is added (at the top, before everything else). |
| add_rights | Boolean | If true then DDL for user & role privileges is added (at the bottom, after everything else). |
| store_in_table | Boolean | If true, the entire output is stored in the table "DB_HISTORY"."DATABASE_DDL" before the output is displayed. |

## Execution

You can execute the script with the below statement:


```"code-sql"
-- parameters: add_user_structure, add_rights, store_in_table execute script create_db_DDL(true, true, false);
```
## Additional References

* The script itself is found on Github: [create_db_ddl.sql](https://raw.githubusercontent.com/exasol/exa-toolbox/master/utilities/create_db_ddl.sql)
