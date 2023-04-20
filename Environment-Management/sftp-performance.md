# SFTP performance 
## Scope

When using an SFTP server as the source or target in IMPORT/EXPORT statements or for Remote Archive Volumes, the network performance may be slow. In some cases, using an SFTP server as a Remote Archive Volume may also cause the status "connection problems."

## Diagnosis

You can verify that an SFTP server is the source or target system by: 

1. In case of an IMPORT/EXPORT query: checking if the query or connection host has the syntax SFTP:// at the front
2. In case of Backups, checking if the Archive URL contains SFTP://

## Explanation

SFTP only delivers a network bandwidth of up to 10 MB/s. This is due to a limitation in a 3rd party software required for remote access and may change in the future.

## Recommendation

If a higher network bandwidth is required, use alternative protocols like FTP (unencrypted) or FTPS (implicit or explicit). These usually deliver maximum network bandwidth.

## Additional References

* [Create Remote Archive Volume](https://docs.exasol.com/administration/on-premise/manage_storage/create_remote_archive_volume.htm)


*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 