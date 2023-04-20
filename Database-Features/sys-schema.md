# SYS Schema 
## Background

Exasol offers numerous system tables describing the metadata of the database and the current status of the system. This article will describe the contents of the SYS schema 

## Explanation

## General Information

These system tables are located in the "SYS" schema, but are automatically integrated into the current namespace. This means that if an object with the same name does not exist in the current schema, they can be queried without stating the schema name, "SYS". Otherwise, the system tables can be accessed via the respective schema-qualified name, SYS.<table_name> (e.g. "SELECT * FROM SYS.DUAL").

There are some system tables that are critical to security, these can only be accessed by users with the "SELECT ANY DICTIONARY" system privilege (users with the DBA role have this privilege implicitly). This includes all system tables with the "EXA_DBA_" prefix.

There are also system tables to which everyone has access, however, the content of these is dependent on the current user. In EXA_ALL_OBJECTS, for example, only the database objects the current user has access to are displayed.

## System table classes

In general Exasol's system tables divide into three classes:

* DBA: Detailed information for all appropriate objects
* ALL: Limited information on all appropriate objects to which the current user has access (any privilege)
* USER: Detailed information for all appropriate objects owned by the current user

Example:

* EXA_DBA_TABLES shows all tables in the database
* EXA_ALL_TABLES shows all tables to which the current user has access via a privilege
* EXA_USER_TABLES shows all tables owned by the current user

You can find a complete list of the available system tables on [our documentation page](https://docs.exasol.com/sql_references/metadata/metadata_system_tables.htm#Metadata_System_Tables)

## Additional References

* [List of System Tables](https://docs.exasol.com/sql_references/metadata/metadata_system_tables.htm#Metadata_System_Tables)
* [EXA_STATISTICS](https://exasol.my.site.com/s/article/EXA-STATISTICS)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 