# Using multiple disks per node in AWS 
This article describes the process of setting up nodes with multiple EXAStorage disks in order to maximize throughput. For best performance, it is recommended that at least one 1TB GP2 SSD (3000IOPS and ~150MB/s) is being used. Please be aware that this process requires the re-installation of the cluster nodes, which implies that all data will be lost and that is why a remote backup is mandatory before proceeding.

### Calculating the optimal amount of disks

Example: Instance type m4.10xlarge

* Provides a maximum disk throughput of 4000mbps (~500MB/s)
* Optimal disk setup 3x1TB GP2 SSDs (3x150MB/s -> 450MB/s)
* The remaining 50MB/s are used for the operating system

### Step-by-step instructions:

a. Stop database instances   
b. Stop EXAStorage service  
c. Set **Install** flag for all data nodes by selecting all the nodes from the **Nodes** tab, then select **Set Install Flag** from the **Actions** tab and click **Execute**  
d. Edit Disks of each node by going to **Nodes - n0011- Disks** and add additional disks

1. Select d04_storage and click **Edit**
2. Click **Add**, each device requires one separate field
3. Fill in additional device names, e.g. “/dev/xvdd, /dev/xvde, …” and click **Apply**
4. Repeat steps for all data nodes

e. Create additional EC2 volumes (same size 1TB) using EC2 console, pay attention to the Availability Zones  
f. Attach volumes to the data nodes using EC2 console, use the very same device names as before in EXAoperation, e.g. “/dev/xvdd, /dev/xvde, …”  
g. Reboot nodes though EC2 console  
h. During reboot, data nodes will be reinstalled with the new disks  
i. Once the nodes are up and running, set the **Active flag** by selecting all the nodes from the **Nodes** tab, then select **Set Active Flag** from the **Actions** tab and click **Execute**  
j. Remove EXAStorage Metadata and start EXAStorage  
k. In EXAStorage, add unused disks on all nodesby selecting all nodes and then clicking **Add Unused Disks**  
l. Recreate data volume(s)  
m. Recreate database (optional)  
n. Restore database backup (optional)

