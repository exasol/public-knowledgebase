# Backup Stages 
## Explanation

#### Backup stages

The process of backup creation consists of several steps: 

1. Protect  
During backup creation, all the required reference backups will be protected against removal, e.g. during the creation of a level 1 backup, the corresponding level 0 backup cannot be removed.
2. Write  
The actual creation of a new backup.
3. Validate  
Once the backup is fully written, it will be validated.
4. Unprotect  
After that, the protection of the current backup and of all the corresponding reference backups will be released.
5. Clean-up  
Expired backups will be removed, even the newly created backup if the expire time applies.  
Please note that this operation can take a considerable time, especially if there is a large number of expired backups in the system. Unfortunately, there is no way to predict the duration.

After the successful cleanup, the backup cycle will be reported as finished.  
Please note that during the whole backup procedure (including the clean up step), the database cannot be shut down. If another backup is scheduled and due while the backup run is in progress, it will be queued and executed directly thereafter.

#### Status information

##### EXAoperation

Progress is reported by EXAoperation log services:

| Timestamp | Priority | Service | Message |
| --- | --- | --- | --- |
| 2014-06-16 09:30:01.650358 | NOTICE | exa_db1 | Backup started. |
| 2014-06-16 09:31:10.218319 | NOTICE | exa_db1 | Remove of expired backups started. |
| 2014-06-16 09:54:59.587537 | NOTICE | exa_db1 | Remove of expired backups finished. |
| 2014-06-16 09:55:00.204568 | NOTICE | exa_db1 | Backup finished. |

##### Exasol database

The system table SYS.EXA_SYSTEM_EVENTS records the start and stop events, but it does not present the single backup steps:

| MEASURE_TIME | EVENT_TYPE | DBMS_VERSION | NODES |
| --- | --- | --- | --- |
| 2014-06-16 22:30:01.650358 | BACKUP_START | 4.2.10 | 4 |
| 2014-06-16 22:55:00.204568 | BACKUP_END | 4.2.10 | 4 |

## Additional References

<https://exasol.my.site.com/s/article/How-to-calculate-the-backup-duration-from-the-system-events-table>

<https://exasol.my.site.com/s/article/Synchronising-backups-between-clusters>

