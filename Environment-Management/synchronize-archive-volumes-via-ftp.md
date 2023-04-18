# Synchronize Archive Volumes via FTP 
## Background

With this UDF (backup_copy_ftp.sql) written in Python, you can easily synchronize archive volumes between clusters. Transport is TLS encrypted (self._ftp = FTP_TLS). After volumes have been initially synchronized, all files added or deleted will be added or deleted in the target archive volume. This UDF does not support synchronizing specific days or backup IDs, but it can be easily adjusted to your needs. Parallelism is handled by the database. So for best performance, the number of database and master nodes of the target archive volume should be the same.

![](images/UDF_sync_volumes.PNG)

## Prerequisites

* Your Remote Archive Volumes must be accessible to the Exasol cluster.
* The user creating the UDF must have permission to create the script in a schema

## How to synchronize archive volumes via FTP

In this section, you can replace the title of "How To ..." to something that fits the theme better. 

## Step 1: Create the UDF

Open the attached file (backup_copy_ftp.sql) and create the script in the schema of your choice. Within the UDF, you should adjust these variables accordingly: 


```markup
LOCAL_URL    = 'ftp://ExaoperationUser:EXAoperationPW@%s/SourceArchiveVolumeID' 
REMOTE_URL   = 'ftp://EXAoperationUser:EXAoperationPW@%s/TargetArchiveVolumeID' 
REMOTE_NODES = [ 'IP node 11', 'IP node 12', 'IP node 13']
```
## Step 2

Once the script is created, you can run it like this:


```markup
SELECT syncBackups(IPROC) FROM EXA_LOADAVG;
```
If needed, you can run this script regularly. 

## Additional Notes

If a synchronization attempt fails, you must cleanup the target volume manually

## Additional References

* [Create Remote Archive Volume](https://docs.exasol.com/administration/on-premise/manage_storage/create_remote_archive_volume.htm)

## Downloads
[backup_copy_ftp.zip](https://github.com/exasol/Public-Knowledgebase/files/9927383/backup_copy_ftp.zip)

