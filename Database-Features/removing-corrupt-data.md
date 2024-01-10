# Identifying and Removing Corrupt Data

## Scope

In very rare occasions, a chain of actions may cause some data in the database to become corrupt. This article gives some tools you can use to help identify if there is corrupt data or not. 

**Corrupt data occurs very rarely, even if your issues match the symptoms in this article. You should only follow the below instructions after discussion with Exasol support.**

## Diagnosis

If something in the database is corrupt, it can manifest itself in several different ways. For example:
* Some queries may cause the database to suddenly restart. The queries may reference certain objects in the database which are corrupt.
* Backups are unable to be written.

## Explanation

Physical data is stored in blocks. The data blocks belong to a column, index, or internal data structure because Exasol is a column-oriented database. If data blocks are removed or not accessible, then any attempt to access that block will crash the database. This includes queries reading certain columns, indexes, statistics, or other data structure, as well as backups. In this case, the database is in an inconsistent state and requires intervention.

## Recommendation

Depending on the setup of the database and the effort to perform the below tasks, there are the following options:

### 1. Restore from Backup
If we identify that the database is an inconsistent state and there is a recent backup (from before the event which caused the corruption), than a quick option is to restore the database from the latest available backup. This action would cause a downtime which corresponds to the time required to write the full and incremental backups. In addition, any data which was added to the database since the latest  backup would need to be reloaded into the database. 

Note: If hardware errors (such as multiple defective disks) cause data loss or corruption, local backups may also be affected and you may need to restore from a remote backup in that case. 

For information on restoring the database from a backup, see [Restore Database from Backup](https://docs.exasol.com/db/latest/administration/on-premise/backup_restore/restore_database.htm).

### 2. Identify and Delete Corrupt Data
It's possible to try to identify the objects which have the corrupt data. Depending on the size of the database, this option may be very time-consuming, and in the end, may not find all corrupt data. The following scripts will only help find corrupt data that is stored in a table/column, statistics, or indexes. If data corresponding to other data structures which are not checked in the below scripts are corrupt, then it may not be possible to remove this data. This option gives you the chance to "save" the database and not have to perform a restore, **but does not provide any guarantees**. 

Save the below script into a file called `corrupt_data_check.sql` and run the below script using [Exaplus CLI](https://docs.exasol.com/db/latest/connect_exasol/sql_clients/exaplus_cli/exaplus_cli.htm). It will generate a list of SQL statements which forces the database to read all columns of every table in the entire database. 

```sql
set heading off;
set verbose off;
set linesize 20000;
spool /tmp/check_all_columns.sql;
SELECT '/*"' || COLUMN_SCHEMA || '"."' || COLUMN_TABLE || '"*/ ' || 'SELECT '||GROUP_CONCAT(CASE WHEN column_type='BOOLEAN' THEN 'COUNT("'||column_name||'")' WHEN column_type LIKE '%CHAR%' THEN 'MIN(LENGTH("'||column_name||'"))' ELSE 'MIN("'||column_name||'")' END ORDER BY column_ordinal_position)||' FROM "'||column_schema||'"."'||column_table||'";' FROM SYS."$EXA_SYS_COLUMNS_BASE" where column_schema='EXA_STATISTICS' and column_object_type='TABLE' group by column_table,column_schema order by column_table desc;
SELECT '/*"' || COLUMN_SCHEMA || '"."' || COLUMN_TABLE || '"*/ ' || 'SELECT '||GROUP_CONCAT(CASE WHEN column_type='BOOLEAN' THEN 'COUNT("'||column_name||'")' WHEN column_type LIKE '%CHAR%' THEN 'MIN(LENGTH("'||column_name||'"))' ELSE 'MIN("'||column_name||'")' END ORDER BY column_ordinal_position)||' FROM "'||column_schema||'"."'||column_table||'";' FROM SYS.EXA_DBA_COLUMNS where column_object_type='TABLE' group by column_table,column_schema order by column_table desc;
spool /tmp/check_all_columns.log;
set heading on;
set verbose on;
@/tmp/check_all_columns.sql;
```

To execute the file, run `exaplus -u <username> -p <passwd> -c <connection string> -f corrupt_data_check.sql`. 

The script will run through the entire script and store the output into /tmp/check_all_column.log. Once it's finished, do the following:
1. Investigate `/tmp/check_all_column.log` and find any queries which return an error message. The table which causes an error message contains corrupt data and should be dropped.
2. Save the DDL of the object. Many SQL Editors offer the ability to save the DDL of the object, however we also have a script to help with this. For more information, see [Create DDL for a Table](create-ddl-for-a-table.md).
3. Drop the table. For more information, see [DROP TABLE](https://docs.exasol.com/db/latest/sql/drop_table.htm).
4. Re-create the table using the saved DDL.
5. Reload the data into the table from another source. 

If one of the statistics tables fails, contact Exasol to delete the corresponding data. Once all of the corrupt objects are dropped, re-run the above script to make sure there are no errors. 

If the database is still crashing after all of the tables are fixed, you can try to drop all of the indexes in case one of them was also corrupted. Save the below script into a file called `recreate_indexes.sql` and run the below script using [Exaplus CLI](https://docs.exasol.com/db/latest/connect_exasol/sql_clients/exaplus_cli/exaplus_cli.htm). It will generate a list of SQL statements which drops and re-creates all indexes on the database.



```sql
set heading off;
set verbose off;
set linesize 20000;
spool /tmp/enforce_indexes.sql;
select 'ENFORCE '||case when IS_LOCAL then 'LOCAL' else 'GLOBAL' end||' INDEX ON "'||INDEX_SCHEMA||'"."'||INDEX_TABLE||'" ('||GROUP_CONCAT(('"'||COLUMN_NAME||'"')  order by
ordinal_position)||');' from "$EXA_INDEX_COLUMNS" where INDEX_TABLE not like 'RPL:%'  group by index_object_id, index_schema, index_table, is_local order by COUNT(*) ASC;
spool /tmp/drop_indexes.sql;
select 'DROP '||case when IS_LOCAL then 'LOCAL' else 'GLOBAL' end||' INDEX ON "'||INDEX_SCHEMA||'"."'||INDEX_TABLE||'" ('||GROUP_CONCAT(('"'||COLUMN_NAME||'"')  order by
ordinal_position)||');' from "$EXA_INDEX_COLUMNS" where INDEX_TABLE not like 'RPL:%'  group by index_object_id, index_schema, index_table, is_local order by COUNT(*) ASC;
spool /tmp/index_logs.log;
set heading on;
set verbose on;
@/tmp/drop_indexes.sql;
@/tmp/enforce_indexes.sql;
```

To execute the file, run `exaplus -u <username> -p <passwd> -c <connection string> -f recreate_indexes.sql`. You can view `/tmp/index_logs.log` or auditing in the database to ensure that all queries executed successfully.

Note - the database will automatically create indexes as needed, but the initial queries may run longer while they are creating indexes. For this reason, we recommend to re-create the indexes immediately after they are dropped.  

**If after all of the above actions, the database is still restarting during query execution, then this may point to the fact that an underlying data structure was corrupted. In this case, you may need to export all of the data (for example, into CSV files), and re-load the data.**

### 3. Re-create Database from Metadata

If all of the data is easily restorable from different sources and there is no valid remote backup present, the fastest option may be to save the Metadata (DDL of all objects) of the database, delete the database, create a new database, restore the metadata, and reload all of the data. Exasol provides a [script](https://raw.githubusercontent.com/exasol/exa-toolbox/master/utilities/create_db_ddl.sql) to save the metadata of the entire database. In this script, all schemas, tables, views, scripts, functions, users, roles, permissions, and connections are created. However, any user or connection passwords are lost and must be reset afterwards. For more information, see [Create DDL for the entire database](create-ddl-for-the-entire-database.md).

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 