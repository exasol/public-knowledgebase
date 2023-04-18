# Add new EXAStorage disks without reinstalling the nodes 

For version 6.0 and newer, you can add new disks without reinstalling the nodes by adding them to a new partition. This article will describe how to accomplish this task.

**1. Shutdown all databases**

Navigate to "EXASolution", select the database and click "Shutdown". 

Please make sure that no backup or restore process is running when you shut down the databases. 

**2. Shutdown EXAStorage** 

Navigate to "EXAStorage" in the menu and click on "Shutdown Storage Service"

**3. Hot-plug disk device(s):**

This has to be done using your virtualization software. In the case of using physical hardware, add the new disks, boot the node and wait until the boot process finishes (this is necessary to continue). 

**4. Open the disk overview for a node in EXAoperation:** 

If the "Add Storage disk" button does not show up, the node has not been activated yet and still remains in the "To install" state. If the node has been installed, set the "active" flag on the nodes.  

**5. Add disk devices to the new EXAStorage partition:**

Press the button "Add"and choose the newly hot-plugged disk device from the list showing devices that are currently unused. When adding multiple disk devices, this procedure has to be repeated for each disk device. Please note that multiple disk devices will always be assembled as RAID-0 in this process. Press the button "Add" again afterward.

**6. Reboot cluster node using EXAoperation:**

Reboot the cluster node and wait until the boot process is finished.

**7. Start EXAStorage and use the newly added devices as a new partition:**

(e.g. EXAStorage -> n0011 -> Select unused disk devices -> "Add devices") Please note that already existing volumes cannot be used for this disk. However, the disk can be used for new data/archive volumes.

