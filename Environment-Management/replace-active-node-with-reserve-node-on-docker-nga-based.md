# Replace Active Node with Reserve Node on Docker/NGA based systems 
## Background

For database instances that are running with one or more reserve nodes, it is possible to swap an active node with a reserve node. You might need to do this in the case of a hardware problem with the active node, as an example. The following steps are required to perform the swap:

1. Shut down the database instance(s)
2. Switch nodes of the database instance(s)
3. Start up the database instance(s)
4. Move the data node to the reserve node

At the end of the procedure, the node that was previously the reserve node is active. 

## Prerequisites

The procedure requires a maintenance window of at least 15 minutes.

* Before you continue with the below steps, make sure the reserve node on EXAStorage is online and running without any errors or issues. If there any are issues with the reserve node, when you restart the database, the reverse node may not function as expected.
* During this procedure, data is recovered from one node to another. The performance of the database is reduced until the data has fully been transferred to the target node.
* Data redundancy of the data volume should be at least 2.

## How to Replace Active Node with Reserve Node on Docker/NGA based systems

### Step 1: Shut down the database instance(s)

In order to shut down the database instances, we can use the "dwad_client" command. The syntax of the command is:


```python
dwad_client stop-wait {database_name}
```
The database instance name(s) can be found via:


```python
dwad_client shortlist
```
In order to verify the state of database instance(s) you can use the command below:


```python
dwad_client list
```
### Step 2: Switch nodes of the database instance(s)

In order to switch nodes:


```python
dwad_client switch-nodes {database_name} {active node} {reserve node}
```
In order to verify the state of nodes use the **"cosps -N"** command.

You can list of nodes and find the current reserve node via:


```python
dwad_client sys-nodes {database_name}
```
### Step 3: Start up the database instance(s)

In order to start up the database instances, we can use the "dwad_client" command. The syntax of the command is:


```python
dwad_client start-wait {database_name}
```
### Step 4: Move the data node to the reserve node

In order to start up the database instances, we can use the "csmove" command. The syntax of the command is:


```python
csmove -s {source node ID} -d {destination node ID} -m -v {volume ID}
```
- Source and Destination node IDs can be found via the **"cosps -N"** command.

- The volume ID can be found via the **"csinfo -v"** command. Please check the volume labels in order to verify the data volume. for example:


```markup
 === Labels ===  
 Name : 'DataVolume1' (#)  
 pub  : 'DB1_persistent'
```
After starting the moving procedure the data volume will start the data recovery process automatically. The performance of the database is reduced until the data has fully been transferred to the target node.

You can monitor the recovery process via the **"cstop"** command.

* Run "cstop" command
* Press 'r' for recovery
* Press 'a' to add node -> enter node number (or 'a' for all)

## Additional Notes

##### This procedure also can be followed for on-premise and cloud deployments.

In case of the redundancy of the data volume is less than 2 the command below can be used for increase redundancy.


```markup
 csresize -i -l1 -v{VID} 
```
Please run only run once otherwise redundancy will be increased to **3.**

## Additional References

Here I link to other sites/information that may be relevant.

<https://docs.exasol.com/administration/aws/nodes/replace_active_node.htm>

<https://docs.exasol.com/administration/on-premise/nodes/replace_active_node.htm>

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 