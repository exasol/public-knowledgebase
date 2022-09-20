# Backup of only selected schemas 
## Problem

It's currently not possible to include only specified schemas or to exclude some schemas from the backup process.  
The backup "knows" nothing about schemas or other database objects.

## Solution

It's however possible to restore only some data by starting a backup in a virtual access mode and transfer the requested data manually by using IMPORT/EXPORT commands.

## Additional References

Please consider Virtual Access on Database Backup

* [Virtual Access on Database Backup in Documentation](https://docs.exasol.com/administration/on-premise/backup_restore/virtual_access_on_backup.htm)
* [Virtual-access on database backups in Community](https://community.exasol.com/t5/database-features/virtual-access-on-database-backups/ta-p/813)
