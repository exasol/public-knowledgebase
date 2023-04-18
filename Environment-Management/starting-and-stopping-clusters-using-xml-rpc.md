# Starting and stopping clusters using XML-RPC 
### Synopsis

This article depicts the steps required to start a cluster when all nodes are powered off and how to shut a cluster down using the EXAoperation XML-RPC interface.

The python snippets are mere examples for the usage of the XML-RPC function calls and provided as-is. Please refer to the EXAoperation manual for details and further information on XML-RPC. 

### Alphabetical list of referenced XML-RPC calls



| Function | Context | Description |
| --- | --- | --- |
| callPlugin | Cluster | Execute a call to an EXAoperation plugin |
| getEXAoperationMaster | Cluster | Return the node of the current EXAoperation master node |
| getDatabaseConnectionState | Database instance | Get connection state of an EXASolution instance |
| getDatabaseConnectionString | Database instance | Return the connection string of an EXASolution instance as used by EXAplus and EXASolution drivers |
| getDatabaseList | Cluster | Lists all database instances defined on the cluster |
| getDatabaseOperation | Database instance | Get current operation of an EXASolution instance |
| getDatabaseState | Database instance | Get the runtime state of an EXASolution instance |
| getHardwareInformation | Cluster | Reports information about your system's hardware as provided by [dmidecode](https://www.nongnu.org/dmidecode/) |
| getNodeList | Cluster | Lists all defined cluster nodes except for license server(s) |
| getServiceState | Cluster | List the cluster services and their current runtime status |
| logEntries | Logservice | Fetch messages collected y a preconfigured EXAoperation logservice |
| shutdownNode | Cluster | Shutdown (and power off) a cluster node |
| startDatabase | Database instance | Start an EXASolution instance |
| startEXAStorage | Storage service | Start the EXAStorage service |
| startupNode | Cluster | Cold start a cluster node |
| stopDatabase | Database instance | Stop an EXASolution instance |
| stopEXAStorage | Storage service | Stop the EXAStorage service |

### Establishing the connection to EXAoperation

To send XML-RPC requests to EXAoperation, please connect to the EXAoperation HTTP or HTTPS listener and provide the base URL matching to the context of a function call as described in the EXAoperation manual (chapter "XML-RPC interface") and listed in the table below.

The code examples in this article are written in Python (tested in versions 2.7 and 3.4).


```"code-java"
import sys

if sys.version_info[0] > 2:
    # Importing the XML-RPC library in python 3
    from xmlrpc.client import ServerProxy
else:
    # Importing the XML-RPC library in python 2
    from xmlrpclib import ServerProxy

# define the EXAoperation url
cluster_url = "https://user:password@license-server/cluster1"

# create a handle to the XML-RPC interface
cluster = ServerProxy(cluster_url)
```
### Startup of a cluster

##### 1. Power-on the license server and wait for EXAoperation to start

License servers are the only nodes able to boot from the local hard disk. All other (database/compute) nodes receive their boot images via PXE. Hence, you need to have at least one license server up and running to kick-start the rest of the cluster.

Physically Power-on the license server and wait until the EXAoperation interfaces are connectible.


```"code-java"
cluster_url = "https://user:password@license-server/cluster1"

while True:
    try:
        cluster = ServerProxy(cluster_url)
        if cluster.getNodeList():
            print("connected\n")
            break
    except:
        continue
```
##### 2. Start the database/compute nodes

Please note that The option to power-on the database nodes using startupNode() is only usable if the nodes are equipped with an out-of-band management interface (like HP iLO or Dell iDRAC) and if this interface is configured in EXAoperation. Virtualized environments (such as vSphere) provide means to automate the startup of servers on a sideband channel.


```"code-java"
for node in cluster.getNodeList():     
 cluster.startupNode(node) 
```
The function getNodeList returns the list of database nodes currently configured in EXAoperation but it does not provide information about the availability in the cluster. You may check if a node is online by querying the node's hardware inventory.


```"code-java"
for node in cluster.getNodeList():
    if 'dmidecode' in cluster.getHardwareInformation(node):
        print("node {} is online\n".format(node))
    else:
        print("node {} is offline\n".format(node))
```
The boot process itself can be monitored by following the messages in an appropriate logservice. Look for messages like 'Boot process finished after XXX seconds' for every node.


```"code-java"
logservice_url = "https://user:password@license-server/cluster1/logservice1"
logservice = ServerProxy(logservice_url)
logservice.logEntries()
```
It is vital that all cluster nodes are up and running before you proceed with the next steps.

##### 3. Start the EXAStorage service

EXAStorage provides volumes as persistence layer for EXASolution databases. This service does not start on boot automatically.

The startEXAStorage function returns 'OK' on success or an exception in case of a failure.


```"code-java"
cluster_url = "https://user:password@license-server/cluster1"
storage_url = "https://user:password@license-server/cluster1/storage"

cluster = ServerProxy(cluster_url)
storage = ServerProxy(storage_url)

# start the Storage service
storage.startEXAStorage()

# check the runtime state of all services
cluster.getServiceState()
```
The getServiceState call returns a list of all cluster services. Ensure that all of them indicate the runtime state 'OK' before you proceed.


```"code-java"
[['Loggingd', 'OK'], ['Lockd', 'OK'], ['Storaged', 'OK'], ['DWAd', 'OK']] 
```
##### 4. Start the EXASolution instances

Iterate over the EXASolution instances and start them:


```"code-java"
for db in cluster.getDatabaseList():
    instance_url = "https://user:password@license-server/cluster1/db_{}".format(db)
    instance = ServerProxy(instance_url)
    instance.startDatabase()
    while True:
        if 'Yes' == instance.getDatabaseConnectionState():
            print("database {} is accepting connections at {}\n".format(
                db, instance.getDatabaseConnectionString()))
            break
```
Again, you may monitor the database startup process by following an appropriate logservice. Wait for messages indicating that the given database is accepting connections.

##### 5. Start services from EXAoperation plugins

Some third-party plugins for EXAoperation may require further attention. This example shows how to conditionally start the VMware tools Daemon.


```"code-java"
plugin = 'Administration.vmware-tools'

# Restart the service on the license server
# to bring it into the correct PID namespace
cluster.callPlugin(plugin, 'n0010', 'STOP')
cluster.callPlugin(plugin, 'n0010', 'START')

for node in cluster.getNodeList():
    if 'vmtoolsd is running' not in cluster.callPlugin(plugin, node, 'STATUS')[1]:
        cluster.callPlugin(plugin, node, 'START')
```
### Shutdown of a cluster

The shutdown of a cluster includes all actions taken for the startup in reverse order. To prevent unwanted effects and possible data loss, it's commendable to perform additional checks on running service operations.

Example


```"code-java"
license_server_id = "n0010"
exaoperation_master = cluster.getEXAoperationMaster()

if exaoperation_master != license_server_id:
    print("node {} is the current EXAoperation master but it should be {}\n".format(
        exaoperation_master, license_server_id))
```
If the license server is not the EXAoperation master node, please log into EXAoperation and move EXAoperation to the license server before you continue.

##### 1. Shutdown of the EXASolution instances

Iterate over the EXASolution instances, review their operational state and stop them.


```"code-java"
for db in cluster.getDatabaseList():
    instance_url = "https://user:password@license-server/cluster1/db_{}".format(db)
    instance = ServerProxy(instance_url)

    state = instance.getDatabaseState()
    if 'running' == state:
        operation = instance.getDatabaseOperation()
        if 'None' == operation:
            instance.stopDatabase()
            while True:
                if 'setup' == instance.getDatabaseState():
                    print("database {} stopped\n".format(db))
                    break
        else:
            print("Database {} is currently in operation state {}\n".format(db, operation))
    else:
        print("Database {} is currently in runtime state {}\n".format(db, state))
```
##### 2. Shutdown of the EXAStorage service

Please assure yourself that all databases are shut down properly before stopping EXAStorage!


```"code-java"
cluster_url = "https://user:password@license-server/cluster1"
storage_url = "https://user:password@license-server/cluster1/storage"

cluster = ServerProxy(cluster_url)
storage = ServerProxy(storage_url)

storage.stopEXAStorage()
cluster.getServiceState()
```
The state of the Storaged will switch to 'not running':


```"code-java"
[['Loggingd', 'OK'], ['Lockd', 'OK'], ['Storaged', 'not running'], ['DWAd', 'OK']] 
```
##### 3. Shutdown of the cluster nodes and of the license server(s) at last


```"code-java"
for node in cluster.getNodeList():
    cluster.shutdownNode(node)

license_servers = ['n0010',]
for ls in license_servers:
    cluster.shutdownNode(ls) 
```
The last call triggers the shutdown of the license server(s) and therefore terminate all EXAoperation instances.

