# Synchronising  backups between clusters 
In case of using two or more database clusters, backups can be stored "cross-over" for fail-safety reasons. The scenario might look like this:


```
         CLUSTER 1                             CLUSTER 2    +-------------------+                +---------------------+    |      DB(1)---------------+         |         DB(2)       |    |                   |      |         |           |         |    |                   |      |         |           |         |    |  Archive Volume <------------------------------+         |    |                   |      |         |                     |    |                   |      |------------> Archive Volume   |    +-------------------+                +---------------------+ 
```
To achieve this, two remote volumes must be defined:

1. The first one in cluster 1, referencing an archive volume in cluster 2. In this example, we reference a volume v0002:   
```
ftp://{IP address or comma-separated IP addresses in cluster 2}:2021/v0002 
```
   For user and password, enter a valid EXAoperation account of cluster 2.
2. The second one in cluster 2 referencing an archive volume in cluster 1.

Please note: In case, backups should also be usable by the respective remote database (e.g. database 2 should be able to restore a backup from within its local archive volume written by remote database 1), the remote archive volume option


```
nocompression 
```
must be used.

Prior to version 6.0, it was not possible to use this approach for creating backups cross-wise.

