# Database Metadata Backup Concept 
## Article: Metadata Backup

## Background

## How it works

The file contains several scripts which will copy the DDL for all objects in the database. It also contains the necessary scripts to restore the metadata. If the config file is set up correctly, "_backup._sh" performs the following tasks: 

1. Creates the specified directory. This is where all of the files will be stored.
2. Connects to the database using an Exaplus profile (must be created beforehand).
3. Once connected to the database, the script creates a schema "BACKUP_SCRIPTS" and 2 scripts which are used in the backup process.
4. EXPORT statements are generated using the database script "BACKUP_SYS" for several system tables which can be referenced later on. The CSV files are saved in the './ddl/' path.
5. A database "*restore_sys.sql*" script is created and saved in the './ddl/' path that includes all the commands neccesary to restore the system tables on a new "SYS_OLD" schema.
6. The script executes the database script "METADATA_BACKUP" and creates DDL for all database objects, including schemas, tables, views, users, roles. Limitations in the script are listed at the end.
	1. Specifically, this script will read data from system tables and create the necessary CREATE statements which can be executed at a later time.
	2. The script creates a new schema, stores the data into a table in this new schema, and then exports the table contents into an SQL file to prevent formatting errors. After the export, the schema is dropped.
7. The DDL and CSV's of the old tables are compressed and saved as a .tar.gz file in the './backups' directory or on a different location if "EXTERNAL_DIR" is set on the "config" file.

## Limitations

Creating DDL based on system tables is not perfect and has some limitations and imperfections. To safeguard incorrect DDL creation, the script also saves the system tables which are used in the script. If a DDL is not created perfectly or if you discover imperfections/errors, you can query the system tables directly and create your own DDL.

* invalid (outdated) views and their DCL will not be created
* views and functions for which the schema or object itself was renamed still contain the original object names and may cause an error on DDL execution
* comments at the end of view text may cause problems
* GRANTOR of all privileges will be the user that runs the SQL code returned by the script
* passwords of all users will be 'Start123', except for connections where passwords will be left empty
* functions with dependencies will not be created in the appropriate order
* UDF scripts with delimited identifiers (in- or output) will cause an error on DDL execution
* If authenticating using Kerberos (< 6.0.8), please alter the script BI_METADATA_BACKUPV2 lines 155 and 156
* Comments containing apostrophes (single-quote) will cause an error on DDL execution

Note: This solution has been updated to include new permissions/rights in version 6.1

## Prerequisites

* Linux system
* Exaplus installed
* Database is already created and is able to be connected from the system you are running the scripts
* Database user, which you will connect to the database with, has the following system privileges:
	+ CREATE SCHEMA
	+ CREATE TABLE
	+ CREATE SCRIPT
	+ SELECT ANY DICTIONARY

## How to create a Metadata Backup Concept?

## *Step 1*

Save the attached tar.gz file to a directory of your choice. The only requirements are that the system is Linux-based and that Exaplus command line is installed.

## *Step 2*

Unzip the file:


```"code-java"
tar xf metabackup_vYYYYMMDD.tar.gz
```
## *Step 3*

Create an Exaplus profile with all of the connection details, including database user, password, and connection string. Details on the parameters for Exaplus can be found in the user manual. Example:


```"code-java"
/usr/opt/EXASuite-6/EXASolution-6.0.10/bin/Console/exaplus -u [YOU_USER] -p [YOUR_PASSWORD] -c [DB IP Address]:8563 -wp metadata_backup_profile
```
## *Step 4*

Change directory to the newly created folder:


```"code-java"
cd metabackup 
```
## *Step 5*

Edit config file with the help of following information:

* Global Section:
	+ EXAPLUS = Path to EXAPLUS excluding the exaplus. For the example above, it would be '/usr/opt/EXASuite-6/EXASolution-6.0.10/bin/Console'
	+ PROFILENAME = The name of the profile created in the previous step as (metadata_backup_profile)
* Backup Section:
	+ EXTERNAL_DIR = The path where the metadata backup will be stored if specified. Can be an external filesystem. Should be mounted or available beforehand
	+ SYSPATH = The path where metabackup_vYYYYMMDD.tar.gz was extracted to
	+ DB_NAME = The Database Name
	+ EXAPLUS_TIMEOUT = Timeout for Exaplus (default 300 seconds). If you want to prevent long-running queries, set the timeout accordingly. Please note, for very large databases, it might take over 5 minutes to run all of the scripts, so please set the timeout higher.
	+ EXAPLUS_RECONNECT = Reconnect tries for Exaplus if the connection fails. Default value is set to '1'.

## *Step 6*

Make .SH files executable


```"code-java"
chmod 755 *.sh
```
## *Step 7*

Run backup.sh


```"code-java"
./backup.sh or bash backup.sh
```
## Article: Metadata Restore

## Background

This script will import the CSV's created in the Backup and run all of the CREATE statements.

1. The script opens an Exaplus session, creates a schema called 'SYS_OLD' containing the same system tables that were created in the backup, and then imports the CSV's into these tables.
2. All of the CREATE statements are executed, which restores the 'structure' of the database, however all tables are empty.
	1. Note: During execution, the owner of all objects is the user running the script. At the end of the script, the owner of all schema changes to match the correct owner.
	2. To monitor errors, profiling is enabled by default. You can search through EXA_DBA_PROFILE_LAST_DAY to find commands which were rolled back

## Limitations

* If the database is not empty, some objects may fail to be created if they already exist in the database. Objects will not be overwritten.
* Limitations of the create DDL script may cause errors during the CREATE statements. Please check the restore log, profiling or auditing to identify statements which were not created successfully.
* If restoring to a database running a different version than the database from the backup, the IMPORT of old sys tables may fail due to different columns.

## Prerequisites

* Linux system
* Exaplus command line
* Database is already created and is able to be connected from the system you are running the scripts on
* It is recommended to start the database with auditing ENABLED
* Database user will need extensive CREATE privileges. It is recommended that the user running the scripts has DBA privileges as the following commands will be carried out:
	+ CREATE SCHEMA, TABLE, VIEW, SCRIPT, CONNECTION, ETC
	+ GRANT

## How to apply a Metadata Restore?

## *Step 1*

The restore script can be run from the same system you ran the backup on or a different system. If running the restore on a new system, please follow steps 1-4 found in the Backup instructions to set up the files. NOTE: When setting up your exaplus profile, please enter the information for the database you are restoring to.

## *Step 2*

Unpack the backup tar into the directory of your choice


```"code-java"
tar xf ddl-backup-DB_NAME-YYYY-MM-DD-HH-Mi-SS.tar.gz
```
## *Step 3*

Edit config file with the following information from:

* Backup Section:
	+ SYSPATH = The path where metabackup.tar.gz was extracted to
	+ DB_NAME = The Database Name
* Restore Section:
	+ BACKUP_RESTORE_PATH = The path that you unpacked the backup file to (should end with '/ddls')
	+ RESTORE_SYS_SQL_PATH = The path containing the restore script

## *Step 4*

Run restore.sh


```"code-java"
./restore.sh or bash restore.sh 
```
## Additional References

* <https://www.exasol.com/support/secure/attachment/78805/metadatabackup_v20190418.tar.gz>
* <https://exasol.my.site.com/s/article/Create-DDL-for-the-entire-Database>
* <https://www.exasol.com/support/browse/IDEA-371>

## Downloads
[metadatabackup_v20190418.tar.zip](https://github.com/exasol/Public-Knowledgebase/files/9936966/metadatabackup_v20190418.tar.zip)
