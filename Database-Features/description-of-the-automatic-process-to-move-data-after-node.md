# Description of the automatic process to move data after node failures 
## Background

This article describes the automatic process to move data after node failures

## Symptoms

1. A typical data volume of a database has a redundancy of 2. With this configuration, data on each volume node have one redundancy copy on another volume node. Thus, the failure of one volume node can be handled without data loss.
2. A typical database configuration consists of some active database nodes and one or more reserve nodes. Thus, in combination with a data volume having the redundancy of 2 or higher, the database can be automatically restarted after a node failure.
3. A typical database is configured with the same active nodes as its data volume to ensure data locality.
4. After a volume node failure (and despite any succeeding automatic database restart), the data volume loses the redundancy of one node.

## Explanation

To automatically recover a missing data redundancy in the above-mentioned scenario, a process exists to handle this situation. For this process to work, the user is required to define a Restore Delay in the database configuration (default value is 10 minutes), which means


>  Look at all database and volume nodes 10 minutes after an automatic database restart and try to move data from the offline volume node to the newly utilized database reserve node.
> 
>  

Due to the nature of a data move operation (it is very expensive), this operation should be prevented, if possible.

Thus, this process only moves data under the following circumstances:

1. **the timeout of the restore delay after a database startup has been reached**: In the case of multiple database restarts, e.g. due to hardware failures, do not start data move operations too early.
2. **the database has been restarted automatically**: If a database has been started manually, the current configuration is accepted *as is*.
3. **exactly one volume node is offline**: If all volume nodes are online, the database nodes should be moved instead to match the volume nodes (this requires a user-triggered database restart). If more than one volume node is offline, the operation will not be started, either (and a monitoring error message will be logged).
4. **data can be accessed locally by database after moving data**: If data from the offline volume node can only be moved to a database node, which is not responsible for the management of the appropriate volume node data, the operation will not be started, either (and a monitoring error message will be logged).
