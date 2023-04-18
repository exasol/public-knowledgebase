# Can You Update a Table in a Foreign Database?

## Question
Here's another question I couldn't find in the documentation. 

Is it possible to "update" or "delete" the connected database via a connection (via OCI or JDBC). So far I only found information about import and export.

Background: We set up a permanent synchronization of an Oracle database in the Exasol DB by using a trigger to first log all changed table records with their primary keys in a synchronization table. Exasol should then import the changed data from this log table. But now we have to inform the source database via a concrete update or delete on this sync table which data has already been transferred.

FYI: The sync table in the source DB looks like this:
```
Create Table CSB_PL_Sync_Queue
(
id NUMBER GENERATED ALWAYS AS IDENTITY,
sync_status int ,
sync_command varchar(20) ,
sync_table_name varchar(100) ,
sync_where_clause varchar(400) ,
datetime_created date default sysdate ,
datetime_updated date,
user_created char(20) default user
)
```
Specifically, we want to update the Sync Status field from 0 to 1, or simply delete the data record if the import of the corresponding line in Exasol was successful.

Thank you for your response.

## Answer
To answer the question a little more directly: as far as I know it is at least not direct (an exa-* please correct me if I'm spreading untruth here),
since connection objects are "homed" in the IMPORT and EXPORT context.

If you absolutely have to do it at the level of a SQL statement from EXA, the following would be possible, although not necessarily recommended:

export (select &lt;your-table-conform-colum-list&gt; from dual where 0=1)
INTO ORA AT &lt;your-connection-here&gt; TABLE &lt;your-table-here&gt; CREATED BY 'update CSB_PL_Sync_Queue set Sync-Status=1';


It's worth knowing that this works, but for a permanent use case like the one described here, I would definitely prefer littlekoi's suggestion.

You may want to implement a simple ETL script, which is going to:

1) Check if something needs to be imported / synced.
2) Run the actual IMPORT.
3) Set "sync-status" in external database.

Running a simple query in Oracle is very cheap. Running a simple query in Exasol is quite expensive due to all the multi-node syncronisation, distributed transaction management, etc. And the Exasol ends up doing nothing but connecting to external database, running query and waiting.

It's not a problem if you have 1-5 parallel loads. But it might be a problem if you'll have 20+ parallel imports, and if you'll ever experience any slowdowns / locks / errors in Oracle.