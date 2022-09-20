# Create DDL for a table 
* ## Background

 Most Database Browsers include the ability to generate DDL for a database object (or multiple). For example, the instructions to do this in DBVisualizer are found [here](http://confluence.dbvis.com/display/UG100/Viewing+the+View+DDL) and for DBeaver [here](https://dbeaver.com/docs/wiki/Database-Navigator/). The following script will also create DDL for a single table when one of those other options are not available: [create_table_ddl.sql](https://github.com/exasol/exa-toolbox/blob/master/utilities/create_table_ddl.sql).

   ## Explanation

 The attached file provides a Lua script to do the same.

 Example call:

   
```"code-sql"
execute script exa_toolbox.create_table_ddl('SOURCE_SCHEMA', 'SOURCE_TABLE', 'TARGET_SCHEMA', 'TARGET_TABLE', true) ; 
```
   If the last parameter is 'true', the script will add the "OR REPLACE" option

   ## Additional References


	+ The script itself: [create_table_ddl.sql](https://raw.githubusercontent.com/exasol/exa-toolbox/master/utilities/create_table_ddl.sql)
	+ [DBVisualizer Documentation](http://confluence.dbvis.com/display/UG110/Users+Guide)
	+ [DBeaver Documentation](https://dbeaver.com/docs/wiki/)
	+ [Lua Scripts](https://docs.exasol.com/database_concepts/scripting.htm)
	+ [Create DDL for Database](https://community.exasol.com/t5/database-features/create-ddl-for-the-entire-database/ta-p/1417)
