# Using XML-RPC to manage Docker clusters

**Since database version 8 XML-RPC interface described in <https://github.com/exasol/exaoperation-xmlrpc> is deprecated. Please use ConfD XML-RPC interface in Python: [Use XML-RPC in Python](https://docs.exasol.com/db/latest/confd/confd.htm#UseXMLRPCinPython).**

## Background

ConfD is the EXASOL configuration and administration daemon that runs on all nodes of an EXASOL cluster. It provides an interface for cluster administration and synchronizes the configuration across all nodes. In this article, you can find examples to manage the Exasol docker cluster using XML-RPC.

## Prerequisites and Notes

**Please note that this is still under development and is *not officially supported* by Exasol. We will try to help you as much as possible, but can't guarantee anything.**

Note: *Any SSL checks disabled for these examples in order to avoid exceptions with self-signed certificates*

Note: If you got an error message like ***xmlrpclib.ProtocolError: <ProtocolError for root:testing@IPADDRESS:443/: 401 Unauthorized>*** please login to cluster and reset root password via the **exaconf passwd-user** command.

Note: All of the examples tested with Exasol version 6.2.7 and python 2.7

## Explanation & Examples

We need to create a connection and get a master IP before running any ConfD job via XML-RPC. You can find how to do it below:

Import required modules and get the master IP:

```python
>>> import xmlrpclib, requests, urllib3, ssl 
>>> urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
```

**Get current master IP** (you can use any valid IP in the cluster for this request)

```python
>>> master_ip = requests.get("https://11.10.10.11:443/master", verify = False).content
```

In this case, 11.10.10.11 is the IP address of one of the cluster nodes

**Create connection:**

Note: We assume you've set the root password **"testing".** You can set a password via **exaconf passwd-user** command

```python
>>> connection_string = "https://root:testing@%s:443/" % master_ip 
>>> sslcontext = ssl._create_unverified_context() 
>>> conn = xmlrpclib.ServerProxy(connection_string, context = sslcontext, allow_none=True)
```

### **The list of examples:**

Example 1 - 2: Database jobs

Example 3: Working with archive volumes

Example 4: Cluster Node Jobs

Example 5: EXAStorage Volume Jobs

Example 6: Working with backups

#### Example 1: Database jobs

**How to use ConfD jobs to get the database status and information about a database.**

Run a job to check the status of the database:

Note: In this example we assume the database name is **"DB1"**. Please adjust the database name.

```python
conn.job_exec('db_state', {'params': {'db_name': 'DB1'}}) 
```

Output:

```python
{'result_name': 'OK', 'result_output': 'running', 'result_desc': 'Success', 'result_jobid': '12.2', 'result_code': 0}
```

As you can see in the output the 'result_output' is  'running' and 'result_desc' is 'Success'. This means the database is up and running.

Note: If you want to format the JSON output you can use **pprint** module

Run a job to get information about the database:

```python
>>> import pprint
>>> pprint.pprint(conn.job_exec('db_info', {'params': {'db_name': 'DB1'}}))

{'result_code': 0,
 'result_desc': 'Success',
 'result_jobid': '11.89',
 'result_name': 'OK',
 'result_output': {'connectible': 'Yes',
                   'connection string': '192.168.31.171:8888',
                   'info': '',
                   'name': 'DB1',
                   'nodes': {'active': ['n11'], 'failed': [], 'reserve': []},
                   'operation': 'None',
                   'persistent volume': 'DataVolume1',
                   'quota': 0,
                   'state': 'running',
                   'temporary volume': 'v0001',
                   'usage persistent': [{'host': 'n11',
                                         'size': '10 GiB',
                                         'used': '6.7109 MiB',
                                         'volume id': '0'}],
                   'usage temporary': [{'host': 'n11',
                                        'size': '1 GiB',
                                        'used': '0 B',
                                        'volume id': '1'}]}}
```

#### Example 2: Database jobs. How to list, start and stop databases

Run a job to list databases in cluster:

```python
conn.job_exec('db_list')
```

Output example:

```python
>>> pprint.pprint(conn.job_exec('db_list'))

{'result_code': 0,
 'result_desc': 'Success',
 'result_jobid': '11.91',
 'result_name': 'OK',
 'result_output': ['DB1']}
```

**Stop the DB1 database:**

Run a job to stop database DB1 in cluster:

```python
>>> conn.job_exec('db_stop', {'params': {'db_name': 'DB1'}})

{'result_name': 'OK', 'result_desc': 'Success', 'result_jobid': '12.11', 'result_code': 0}
```

Run a job to confirm the state of the database DB1:

```python
>>> conn.job_exec('db_state', {'params': {'db_name': 'DB1'}})

{'result_name': 'OK', 'result_output': 'setup', 'result_desc': 'Success', 'result_jobid': '12.12', 'result_code': 0}
```

 Note: *'result_output': 'setup': the status of the database is "setup"*

 Run a job to start database DB1 in cluster:

```python
>>> conn.job_exec('db_start', {'params': {'db_name': 'DB1'}})

{'result_name': 'OK', 'result_desc': 'Success', 'result_jobid': '12.13', 'result_code': 0}
```

Run a job to verify the state of the database of DB1 is up and running:

```python
>>> conn.job_exec('db_state', {'params': {'db_name': 'DB1'}})

{'result_name': 'OK', 'result_output': 'running', 'result_desc': 'Success', 'result_jobid': '12.14', 'result_code': 0}
```

#### Example 3: Working with archive volumes

Example 3.1: Add a remote archive volume to cluster

| Name | Description | Parameters |
| --- | --- | --- |
| remote_volume_add | Add a remote volume | vol_type, url <br />**optional**: remote_volume_name, username, password, labels, options, owner, allowed_users<br />**substitutes:** remote_volume_id <br />**allowed_groups:** root, exaadm, exastoradm <br />**notes**: <br />--&gt; 'ID' is assigned automatically if omitted (10000 + next free ID) <br />--&gt; 'ID' must be >= 10000 if specified<br />--&gt; 'name' may be empty (for backwards compat.) and is generated from 'ID' in that case (*"r%04i" % ('ID' - 10000*))<br />--&gt; if 'owner' is omitted, the requesting user becomes the owner |

```python
>>> conn.job_exec('remote_volume_add', {'params': {'vol_type': 's3','url': 'http://bucketname.s3.amazonaws.com','username': 'ACCESS-KEY','password': 'BASE64-ENCODED-SECRET-KEY'}})   

{'result_revision': 18, 'result_jobid': '11.3', 'result_output': [['r0001', 'root', '/exa/etc/remote_volumes/root.0.conf']], 'result_name': 'OK', 'result_desc': 'Success', 'result_code': 0}
```

Example 3.2: list all containing  remote volume names

| Name | Description | Parameter | Returns |
| --- | --- | --- | --- |
| remote_volume_list | List all existing remote volumes | None | a list containing all remote volume names |

```python
>>> pprint.pprint(conn.job_exec('remote_volume_list'))

{'result_code': 0,
 'result_desc': 'Success',
 'result_jobid': '11.94',
 'result_name': 'OK',
 'result_output': ['RemoteVolume1']}
```

Example 3.3: Connection state of the given remote volume

| Name | Description | Parameter | Returns |
| --- | --- | --- | --- |
| remote_volume_state | Return the connection state of the given remote volume, online / Unmounted / Connection problem | remote_volume_name <br />substitutes: remote_volume_id | List of the connection state of the given remote volume on all nodes |

```python
>>> conn.job_exec('remote_volume_state',  {'params': {'remote_volume_name': 'r0001'}})

{'result_name': 'OK', 'result_output': ['Online'], 'result_desc': 'Success', 'result_jobid': '11.10', 'result_code': 0} 
```

#### Example 4: Manage cluster nodes

Example 4.1: get node list

| Name | Description | Parameter | Returns |
| --- | --- | --- | --- |
| node_list | List all cluster nodes (from EXAConf) |  None | Dict containing all cluster nodes. |

```python
>>> pprint.pprint( conn.job_exec('node_list'))

{'result_code': 0,
 'result_desc': 'Success',
 'result_jobid': '11.95',
 'result_name': 'OK',
 'result_output': {'11': {'disks': {'disk1': {'component': 'exastorage',
                                              'devices': ['dev.1'],
                                              'direct_io': True,
                                              'ephemeral': False,
                                              'name': 'disk1'}},
                          'docker_volume': '/exa/etc/n11',
                          'exposed_ports': [[8888, 8899], [6583, 6594]],
                          'id': '11',
                          'name': 'n11',
                          'private_ip': '192.168.31.171',
                          'private_net': '192.168.31.171/24',
                          'uuid': 'C5ED84F591574F97A337B2EC9357B68EF0EC4EDE'}}}             
```

 Example 4.2: get node state

| Name | Description | Parameter | Returns |
| --- | --- | --- | --- |
| node_state | State of all nodes (online, offline, deactivated) |  None |  A list containing a string representing the current node state. |

```python
>>> pprint.pprint(conn.job_exec('node_state'))

{'result_code': 0,
 'result_desc': 'Success',
 'result_jobid': '11.96',
 'result_name': 'OK',
 'result_output': {'11': 'online',
                   'booted': {'11': 'Tue Jul  7 14:14:07 2020'}}}
```

**other available options:**

| Name | Description | Parameter | Returns |
| --- | --- | --- | --- |
| node_add | Add a node to the cluster | priv_net<br />**optional**: id, name, pub_net, space_warn_threshold, bg_rec_limit<br />**allowed_groups:** root, exaadm | int node_id |
| node_remove | Remove a node from the cluster | node_id<br />**optional**: force<br />**allowed_groups:** root, exaadm | None |
| node_info | Single node info with extended information (Cored, platform, load, state) | None | See the output of cosnodeinfo |
| node_suspend | Suspend node, i. e. mark it as "permanently offline". | node_id<br />**allowed_groups:** root, exaadm | mark one node as suspended |
| node_resume | Manually resume a suspended node. | node_id<br />**allowed_groups:** root, exaadm | unmark one suspended node |

#### Example 5: EXAStorage volume jobs

 Example 5.1: list EXAStorage volumes

| Name | Description | Parameter | Returns |
| --- | --- | --- | --- |
| st_volume_list | List all existing volumes in the cluster. | none | List of dicts |

```python
>>> pprint.pprint(conn.job_exec('st_volume_list'))

{'result_code': 0,
 'result_desc': 'Success',
 'result_jobid': '11.97',
 'result_name': 'OK',
 'result_output': [{'app_io_enabled': True,
                    'block_distribution': 'vertical',
                    'block_size': 4096,
                    'bytes_per_block': 4096,
                    'group': 500,
                    'hdd_type': 'disk1',
                    'hdds_per_node': 1,
                    'id': '0',
                    'int_io_enabled': True,
                    'labels': ['#Name#DataVolume1', 'pub:DB1_persistent'],
                    'name': 'DataVolume1',
                    'nodes_list': [{'id': 11, 'unrecovered_segments': 0}],
                    'num_master_nodes': 1,
                    'owner': 500,
                    'permissions': 'rwx------',
                    'priority': 10,
                    'redundancy': 1,
                    'segments': [{'end_block': '2621439',
                                  'index': '0',
                                  'nid': 0,
                                  'partitions': [],
                                  'phys_nid': 11,
                                  'sid': '0',
                                  'start_block': '0',
                                  'state': 'ONLINE',
                                  'type': 'MASTER',
                                  'vid': '0'}],
                    'shared': True,
                    'size': '10 GiB',
                    'snapshots': [],
                    'state': 'ONLINE',
                    'stripe_size': 262144,
                    'type': 'MASTER',
                    'unlock_conditions': [],
                    'use_crc': True,
                    'users': [[30, False]],
                    'volume_nodes': [11]},
                   {'app_io_enabled': True,
                    'block_distribution': 'vertical',
                    'block_size': 4096,
                    'bytes_per_block': 4096,
                    'group': 500,
                    'hdd_type': 'disk1',
                    'hdds_per_node': 1,
                    'id': '1',
                    'int_io_enabled': True,
                    'labels': ['temporary', 'pub:DB1_temporary'],
                    'name': 'v0001',
                    'nodes_list': [{'id': 11, 'unrecovered_segments': 0}],
                    'num_master_nodes': 1,
                    'owner': 500,
                    'permissions': 'rwx------',
                    'priority': 10,
                    'redundancy': 1,
                    'segments': [{'end_block': '262143',
                                  'index': '0',
                                  'nid': 0,
                                  'partitions': [],
                                  'phys_nid': 11,
                                  'sid': '0',
                                  'start_block': '0',
                                  'state': 'ONLINE',
                                  'type': 'MASTER',
                                  'vid': '1'}],
                    'shared': True,
                    'size': '1 GiB',
                    'snapshots': [],
                    'state': 'ONLINE',
                    'stripe_size': 262144,
                    'type': 'MASTER',
                    'unlock_conditions': [],
                    'use_crc': True,
                    'users': [[30, False]],
                    'volume_nodes': [11]}]}
```

 Example 5.2: Get information about volume with id "vid"

| Name | Description | Parameter | Returns |
| --- | --- | --- | --- |
| st_volume_info | Return information about volume with id vid | vid | |

```python
>>> pprint.pprint(conn.job_exec('st_volume_info', {'params': {'vid': 0}}))

{'result_code': 0,
 'result_desc': 'Success',
 'result_jobid': '11.98',
 'result_name': 'OK',
 'result_output': {'app_io_enabled': True,
                   'block_distribution': 'vertical',
                   'block_size': '4 KiB',
                   'bytes_per_block': 4096,
                   'group': 500,
                   'hdd_type': 'disk1',
                   'hdds_per_node': 1,
                   'id': '0',
                   'int_io_enabled': True,
                   'labels': ['#Name#DataVolume1', 'pub:DB1_persistent'],
                   'name': 'DataVolume1',
                   'nodes_list': [{'id': 11, 'unrecovered_segments': 0}],
                   'num_master_nodes': 1,
                   'owner': 500,
                   'permissions': 'rwx------',
                   'priority': 10,
                   'redundancy': 1,
                   'segments': [{'end_block': '2621439',
                                 'index': '0',
                                 'nid': 0,
                                 'partitions': [],
                                 'phys_nid': 11,
                                 'sid': '0',
                                 'start_block': '0',
                                 'state': 'ONLINE',
                                 'type': 'MASTER',
                                 'vid': '0'}],
                   'shared': True,
                   'size': '10 GiB',
                   'snapshots': [],
                   'state': 'ONLINE',
                   'stripe_size': '256 KiB',
                   'type': 'MASTER',
                   'unlock_conditions': [],
                   'use_crc': True,
                   'users': [[30, False]],
                   'volume_nodes': [11]}}         
```

**other options:**

**EXAStorage Volume Jobs:**

| Name | description | Parameters |
|---|---|---|
| st_volume_info | Return information about volume with id vid | vid |
| st_volume_list | List all existing volumes in the cluster. | None |
| st_volume_set_io_status | Enable or disable application / internal io for volume | app_io, int_io, vid |
| st_volume_add_label | Add a label to specified volume | vid, label |
| st_volume_remove_label | Remove given label from the specified volume | vid label |
| st_volume_enlarge | Enlarge volume by blocks_per_node | vid, blocks_per_node |
| st_volume_shrink | Shrink volume by blocks_per_node | vid, blocks_per_node |
| st_volume_append_node | Append nodes to a volume.storage.append_nodes(vid, node_num, node_ids) -> None | vid, node_num, node_ids |
| st_volume_move_node | Move nodes of specified volume | vid, src_nodes, dst_nodes |
| st_volume_increase_redundancy | Increase volume redundancy by delta value | vid, delta, nodes |
| st_volume_decrease_redundancy | decrease volume redundancy by delta value | vid, delta, nodes |
| st_volume_lock | Lock a volume | vid<br />optional: vname |
| st_volume_lock | Unlock a volume | vid<br />optional: vname |
| st_volume_clear_data | Clear data on (a part of) the given volume | vid, num__bytes, node_ids<br />optional: vname |

#### Example 6: Working with backups

Example 6.1: start a new backup

| Name | Description | Parameter | Returns |
| --- | --- | --- | --- |
| db_backup_start | Start a backup of the given database to the given volume | db_name, backup_volume_id, level, expire_time **substitutes**: dackup_volume_name | |

```python
>>> conn.job_exec('db_backup_start', {'params': {'db_name': 'DB1','backup_volume_name': 'RemoteVolume1','level': 0,'expire_time': '10d'}})

{'result_name': 'OK', 'result_desc': 'Success', 'result_jobid': '11.77', 'result_code': 0}
```

Example 6.2: abort backup

| Name | Description | Parameter | Returns |
| --- | --- | --- | --- |
| db_backup_abort | Aborts the running backup of the given database | db_name | |

```python
>>> conn.job_exec('db_backup_abort', {'params': {'db_name': 'DB1'}})  

{'result_name': 'OK', 'result_desc': 'Success', 'result_jobid': '11.82', 'result_code': 0}
```

Example 6.3: list backups

| Name | Description | Parameter |
| --- | --- | --- |
| db_backup_list | Lists available backups for the given database | db_name |

```python
>>> pprint.pprint(conn.job_exec('db_backup_list', {'params': {'db_name': 'DB1'}}))

{'result_code': 0,
 'result_desc': 'Success',
 'result_jobid': '11.99',
 'result_name': 'OK',
 'result_output': [{'bid': 11,
                    'comment': '',
                    'dependencies': '-',
                    'expire': '',
                    'expire_alterable': '10001 DB1/id_11/level_0',
                    'expired': False,
                    'id': '10001 DB1/id_11/level_0/node_0/backup_202007071405 DB1',
                    'last_item': True,
                    'level': 0,
                    'path': 'DB1/id_11/level_0/node_0/backup_202007071405',
                    'system': 'DB1',
                    'timestamp': '2020-07-07 14:05',
                    'ts': '202007071405',
                    'usable': True,
                    'usage': '0.001 GiB',
                    'volume': 'RemoteVolume1'}]}              
```

**other options:**

**Jobs to manage backups:**

| Name | description | Parameters |
| --- | --- | --- |
| db_backups_delete | Delete given backups of given database | db_name, backup list (as returned by 'db_backup_list()') |
| db_backup_change_expiration | Change expiration time of the given backup files |backup volume ID <br />backup_files: Prefix of the backup files, like exa_db1/id_1/level_0) <br />expire_time : Timestamp in seconds since the Epoch on which the backup should expire.|
| db_backup_delete_unusable | Delete all unusable backups for a given database | db_name |
| db_restore | Restore a given database from given backup | db_name, backup ID, restore type ('blocking' | 'nonblocking' | 'virtual access') |
| db_backup_add_schedule | Add a backup schedule to an existing database | db_name, backup_name, volume, level, expire, minute, hour, day, month, weekday, enabled <br />**notes**: <br />--&gt; 'level' must be int <br />--&gt; 'expire' is string (use common/util.str2sec to convert) <br />--&gt; 'backup_name' is string (unique within a DB)|
| db_backup_remove_schedule | Remove an existing backup schedule |  db_name, backup_name |
| db_backup_modify_schedule | Modify an existing backup schedule |  db_name, backup_name <br />**optional:** <br />hour, minute, day, month, weekday, enabled |

## Additional References

* <https://github.com/EXASOL/docker-db>
* [v8, Use XML-RPC in Python](https://docs.exasol.com/db/latest/confd/confd.htm#UseXMLRPCinPython)
* <https://github.com/exasol/exaoperation-xmlrpc>

You can find another article about deploying a exasol database as an docker image in [How to deploy a single-node Exasol database as a Docker image for testing purposes](https://exasol.my.site.com/s/article/How-to-deploy-a-single-node-Exasol-database-as-a-Docker-image-for-testing-purposes)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
