# How to update EXAClusterOS using the command line
## Background

That article guides you through the procedure to update the ClusterOS via the command line.
## Prerequisites

SSH root access to the License Server.
Check the [Update Considerations](https://docs.exasol.com/db/7.1/administration/on-premise/upgrade/update_considerations.htm) before any software update.

## Instructions
1. Copy the update packages (both) to the License Server.
```
rsync -avP EXA*.pkg root@{LS_IP}:/tmp/
```
_or_
```
scp EXA*.pkg root@{LS_IP}:/tmp/
```
2. Make sure **no backup** or **storage recovery** is in progress.
3. Make sure **EXAopeartion is running on the License Server**. Check this in the EXAopeartion section.
4. Go to the Software section and **remove the obsolete EXASolution version(s)**.
5. [Stop the Database.](https://docs.exasol.com/db/7.1/administration/on-premise/manage_database/stop_db.htm)
6. [Stop the Storage Services.](https://docs.exasol.com/db/7.1/administration/on-premise/manage_storage/stop_start_storage_service.htm)
7. [Stop the Cluster Services on the data nodes.](https://docs.exasol.com/db/7.1/administration/on-premise/nodes/actions_on_nodes.htm)
8. SSH into the LS and create the update directory.
```
mkdir /tmp/exasuite_update/
```
9. Extract the package.
```
tar xf EXAClusterOS-7.1.NN_LS-Update.pkg -C /tmp/exasuite_update/
```
10. Start the EXAClusterOS update.
```
$COS_DIRECTORY/share/exaoperation/scripts/exaclusteros_update.sh /tmp/exasuite_update/EXAClusterOS-7.1.NN_LS-Update-CentOS-7.5.NNNN_x86_64.tar.gz
```
11. Check the EXAopeartion log and look for the start and completion messages.
```
tail -f /var/log/logd/EXAoperation.log
[2023-12-07 16:03:29.911675] NOTICE: [Software update] Start update process to EXAClusterOS version 7.1.NN.
[2023-12-07 16:04:10.064588] NOTICE: [Software update] First part of update process succeeded. Please shutdown databases and nodes and restart license server.
```
12. Apply the CentOS security patch update.
```
apply_os_security_updates /tmp/EXASOL-7.1-CentOS-7-CumulativeUpdate-YYYYMMDDHHMM.pkg
```
_Note: In case you see a message like this "Dismiss already applied patchlevel YYYYMMDDHHMM", it means there is no update needed, and you can continue the procedure._

13. Reboot the license node.
14. Check the Software tab and confirm the new version was successfully applied.
15. Make sure there is enough space in the root filesystem (df -h /). If not, try removing some files to release space.
16. [Reboot the data nodes.](https://docs.exasol.com/db/7.1/administration/on-premise/nodes/actions_on_nodes.htm)
17. [Start the Storage Services.](https://docs.exasol.com/db/7.1/administration/on-premise/manage_storage/stop_start_storage_service.htm)
18. [Start the Database.](https://docs.exasol.com/db/7.1/administration/on-premise/manage_database/start_db.htm)
