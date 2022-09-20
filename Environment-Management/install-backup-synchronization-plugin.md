# Install Backup Synchronization Plugin 
## Backup Synchronization Plugin Installation

## **Overview**

The backup synchronization process involves synchronization of data and metadata between clusters on different networks. This document provides you with the steps on how to install the Backup Synchronization plugin on two clusters using XML-RPC. XML-RPC lets you establish communication between the two clusters quickly and easily.

Exasol’s XML-RPC support is implemented using the **xmlrpclib** (<http://docs.python.org/library/xmlrpclib.html>) library that is included with Python 2.2 and later.

## **Recommendations**

* Knowledge of [XML-RPC](https://github.com/EXASOL/exaoperation-xmlrpc/blob/master/EXAoperation_XMLRPC.md)
* Knowledge of SSH Authentication

## **Plugin Installation**

You can follow the below steps to install the backup synchronization plugin on clusters. As an example, let us consider two clusters EDU01 and EDU02.

### **Step 1:** **Uninstall Older Plugins Versions on All Clusters**

Any older plugin installed on the clusters must be uninstalled before you can install the latest plugin. The following sample script deactivates and uninstalls the older plugins on the two clusters *EDU01* and *EDU02*.      


```"code
Sample Script Sample Script to Uninstall Plugin on EDU001from xmlrpclib import Server as xmlrpc import ssl from pprint import pprint as pp from base64 import b64encode server = xmlrpc('https://FTPbackup:***PW***@10.60.101.10/cluster1/') pp(server.showPluginList())  # ['Administration.BackupSync-1.0.1']  pname = 'Administration.BackupSync-1.0.1' nlist = server.getNodeList() pp([[node] + server.callPlugin(pname, node, 'STATUS', '') for node in nlist])  ##[['n0011', 0, 'activated'], ## ['n0012', 0, 'activated'], ## ['n0013', 0, 'activated']]  pp([[node] + server.callPlugin(pname, node, 'DEACTIVATE', '') for node in nlist]) pp([[node] + server.callPlugin(pname, node, 'UNINSTALL', '') for node in nlist]) exit() 
```

```"code
Sample Script to Uninstall Plugin on EDU02from xmlrpclib import Server as xmlrpc import ssl from pprint import pprint as pp from base64 import b64encode server = xmlrpc('https://FTPbackup:***PW***@10.60.102.10/cluster1/') pp(server.showPluginList()) pname = 'Administration.BackupSync-1.0.1' nlist = server.getNodeList() pp([[node] + server.callPlugin(pname, node, 'DEACTIVATE', '') for node in nlist]) pp([[node] + server.callPlugin(pname, node, 'UNINSTALL', '') for node in nlist]) exit()
```
    
**Note:** All credentials and files names used in the sample scripts are example credentials and file names. Please replace them with the correct one for your clusters.

### **Step 2:** **Remove Plugin from EXAoperation**

Once you have deactivated and uninstalled the previously installed plugin, you must remove the entry of the plugin from EXAoperation for all the clusters. Doing this will clear the folders directories previously created. 

You can follow the below steps to remove the plugin from EXAoperation:

1. Log in to **EXAoperation** for the desired cluster and navigate to **Software** under **Configuration**
2. On the right-hand side, select the checkbox next to the plugin you want to remove.
3. Click **Delete** to remove the plugin.

### **Step 3: Upload Latest Plugin to EXAoperation**

You can receive the latest Backup Synchronization Plugin by contacting the Exasol support team.

To be able to use the Backup Synchronization Plugin, it must be first uploaded to EXAoperation and then installed on the clusters.

The lasted plugin must be uploaded through EXAoperation on all clusters (in this example, it must be uploaded to EDU01 and EDU02) by following these steps:

1. In **EXAoperation**, navigate to **Software** under **Configuration**
2. On the right-hand side of the screen, click **Choose File** next to **Software Update File** and click **Submit**.
3. Once the upload is complete, you can see the plugin is listed in the below section of the screen.

### **Step 4:** **Install the Latest Plugin**

After the latest plugin is uploaded through EXAoperation (refer to step 3), you must install it on both the clusters (EDU01 and EDU02). The following sample scripts will install the latest plugins on the clusters. 


```"code
Sample Script to Install Plugin on EDU01nlist = server.getNodeList() pp(server.showPluginFunctions(pname)) {'ACTIVATE': 'Activate plugin.', 'DEACTIVATE': 'Deactivate plugin.', 'GETLOG': 'Return the log output.', 'INSTALL': 'Install plugin.', 'SSHKEY': 'Prepare public key for ssh.', 'STATUS': 'Show status of plugin (not installed, activated, not activated).', 'UNINSTALL': 'Install plugin.', 'UPLOAD_CONFIG': 'Upload configuration.', 'UPLOAD_KEY': 'Upload public key for ssh'}  pp([[node] + server.callPlugin(pname, node, 'INSTALL', '') for node in nlist]) pp([[node] + server.callPlugin(pname, node, 'STATUS', '') for node in nlist])   
```

```"code
Sample Script to Install Plugin on EDU02nlist = server.getNodeList() pp([[node] + server.callPlugin(pname, node, 'INSTALL', '') for node in nlist]) pp([[node] + server.callPlugin(pname, node, 'STATUS', '') for node in nlist])  
```
### **Step 5:** **Create a User in EXAoperation**

You must create a new user with admin role. The user account will be used to access the Exasol backup via FTP. You can use any existing user account with admin role, however, creating a new user for this purpose makes it easy to segregate specific tasks to users.

**Note:** This user must be created on both the clusters. In this case, a user is created through EXAoperation for EDU01 and EDU02 clusters.

To create a new user:

1. In EXAoperation, navigation to **Configuration > Access Management**.
2. Click **Users** tab and click **Add**.
3. Complete the following information for the new user.  
*For example:*
	* ***Login:*** *FTPBackup*
	* ***Title:*** *4FTPbackup*
	* ***Description:*** *4FTPbackup*
	* ***Identification by:*** *Internal*
	* ***Password:*** *Enter the desired password*
4. Click **Add**. A user is created. The new user created will have the role of ‘**User’** by default.
5. To set the role as ‘**Administrator’** for this new user, click the **Roles** tab and select **Administrator** from the **Roles** dropdown list.
6. Click **Apply**.

### **Step 6:** **Create Archive Volume from EXAoperation**

An archive volume must be created on all the clusters (in this example, an archive volume must be created on EDU01 and EDU02) for storing the database backups. As a rule of thumb, for up to 1-3 nodes in a cluster which are also the source nodes, at least one archive node on the destination cluster is recommended.

For more information on Archive volume creation, see [Create Archive Volume](https://www.exasol.com/portal/display/DOC/Create+Data+and+Archive+Volumes).

### **Step 7:** **Create and Upload Configuration File**

To establish a connection between the clusters, you need to create a configuration file which contains the following information:

* The database names
* The start cycles – Unix-like cron format
* Local URL to the backup
* Remote URL to the backup
* Remote nodes and SSH

The configuration file enables you to establish a connection between two clusters. However, if you are connecting to more than one cluster, then you need an exclusive configuration file to connect to each cluster. For example, you need a configuration file to establish a connection between EDU01 and EDU02. Now, if you have a third cluster EDU03, and you want to establish a connection between EDU02 and EDU03, or from EDU03 to EDU01. You must create a new configuration file for each of these connections.

The following are sample configuration files for the clusters: 


```"code
Sample Configuration File for EDU01 #Filename on SupportHost: /home/ssh/client.cfg Connection1 { DATABASE_NAME = exa_db1 START_CYCLE = */2 * * * * LOCAL_URL = ftp://FTPbackup:**PW**@%s/v0003 REMOTE_URL = ftp://FTPbackup:**PW**@%s/v0002 REMOTE_NODES = 10.60.102.11; 10.60.102.12 Verbose = true SSH = client } 
```

```"code
Sample Configuration File for EDU02#Filename on SupportHost: /home/ssh/server.cfg Connection1 { Verbose = true SSH = server }
```
**Note:**

* The connection name in the configuration files must be the same for the source and destination clusters.
* Setting the value for Verbose to true in the configuration file enables verbose logging – which captures more details on  syncing of files – in the EXACluster Monitoring Service.  If this not enabled only errors are logged. This option is disabled by default.

The configuration files created must be uploaded to the clusters. The following sample scripts can be used to upload the configuration files: 


```"code
Sample Script to Upload Configuration File on EDU01nlist = server.getNodeList() config = b64encode(open('/home/ssh/client.cfg').read()) pp([[node] + server.callPlugin(pname, node, 'UPLOAD_CONFIG', config) for node in nlist]) 
```

```"code
Sample Script to Upload Configuration File on EDU02nlist = server.getNodeList() config = b64encode(open('/home/ssh/server.cfg').read()) pp([[node] + server.callPlugin(pname, node, 'UPLOAD_CONFIG', config) for node in nlist]) 
```
### **Step 8:** **Create SSH Key**

SSH key can be used to establish secure connections between the clusters. The following sample script generates the SSH key on the client machine with respect to the connection specified in the configuration file. 


```"code
SSH Keygen Sample Scriptnlist = server.getNodeList() pp(server.showPluginFunctions(pname)) pp([[node] + server.callPlugin(pname, node, 'SSHKEY', 'Connection1') for node in nlist])  >>> pp([[node] + server.callPlugin(pname, node, 'SSHKEY', 'Connection1') for node in nlist])  [['n0011', 0, 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA8V3Au7gr7jmoWIZlbTTNb/ 3Lkku44mlxeC/gTHHvFjgYQSjtFvWZl7i3NIQqrJk4ApQDcqBTRLT8/VNT4PHWyRt+3I ImmGH0D3V9rl+NmCQVjJh/sSKttI5cMR3P6JSg76mhaIjkKddnILHIJVW3R1Q2g+bgr5 R1qaCXQghb9M/mdHdbfTkk7zI41tAchlZrjbcRfRwOMAYOGSHIdegB1qs1kMBbEivcS9 3sKCyXG46dLchQspIeShdwHFjCJDDRYGIWiH4N6M2P50PjGM4lQTyFrJzAD89LYV IfMiN6d+2XTCYCy7W0uezp7OqwBsp2UY31omw9jtSqDn3g5KOIZQ== root@n0011.c0001.exacluster.local']] >>> 
```
**Note:** The ssh key generated can be used only with the connection it is linked to.

 A public key is created for each node.  This public key must be copied and uploaded to the remote server to be able to use SSH authentication.

### **Step 9:** **Upload SSH Key**

The public key generated for the node must be uploaded to the remote server to be able to authenticate using SSH. Create a file (for example - /home/ssh/connection1_ssh_key_file.key) and copy the key generated in the previous step for the node into this file.

The sample script below uploads SSH key for the specific connection to the remote server (in this example, the SSH key is uploaded to EDU02). 


```"code
Sample Script to Upload SSH Key on EDU02nlist = server.getNodeList() # Upload KEY key = b64encode(open('/home/ssh/Connection1_ssh_key_file.key').read ()) pp([[node] + server.callPlugin(pname, node, 'UPLOAD_KEY', key) for node in nlist]) Activate SSH key for "Connection1"  pp([[node] + server.callPlugin(pname, node, 'SSHKEY', 'Connection1') for node in nlist])
```
**Step 10:** **Activate Connection between the two clusters**

Once you have uploaded the SSH key file, the connections on the clusters must be activated to be able to establish a secure connection between them. 


```"code
Sample Script to Activate Connection on EDU01nlist = server.getNodeList() # Upload KEY key = b64encode(open('/home/ssh/Connection1_ssh_key_file.key').read ()) pp([[node] + server.callPlugin(pname, node, 'UPLOAD_KEY', key) for node in nlist]) # Activate SSH key for "Connection1"  pp([[node] + server.callPlugin(pname, node, 'ACTIVATE', 'Connection1') for node in nlist]) 
```
### **Step 11:** **Deactivate Connection between two cluster**

In case you want to deactivate this connection, you can follow the below sample script:


```"code
Sample Script to Deactivate Connection on EDU01nlist = server.getNodeList() pp([[node] + server.callPlugin(pname, node, 'DEACTIVATE', 'Connection1') for node in ['n0011','n0012']]) 
```
