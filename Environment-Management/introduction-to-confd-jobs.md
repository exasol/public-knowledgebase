# Introduction to ConfD Jobs 
***This article is only applicable to Docker installations***

## Overview

ConfD is the Exasol configuration and administration daemon that runs on all nodes of an Exasol cluster. It provides an interface for cluster administration and synchronizes the configuration across all nodes. To do that, it abstracts the administration and configuration tasks into jobs, implements skeletons in a scheduler and delays some job-specific steps into individual jobs. In this way, all jobs are 'pluginable' and ConfD is of great scalability. Besides, ConfD jobs provide a much safer way to update the configuration file 'EXAConf' and to synchronize across nodes automatically on demand. In the meanwhile, ConfD jobs introduce http-based authentication and different granularity for authorization. Therefore, ConfD jobs are recommended for making changes or daily management for an Exasol cluster.

## Deep Dive

ConfD is an evolved version of EXAoperation and newly designed for cloud environments. It adapts with the new architecture and implementation in a few ways.

### Asynchronous scheduling

ConfD scheduler executes and manages the jobs in an asynchronous way. Every job has its own pipeline, in which several stages are defined:

1. *submitted*: they received a job ID and are now waiting in the queue to be scheduled.
2. *scheduled*: the scheduler has examined the job,  accepted (or declined) it, assigned it a new EXAConf revision (if necessary) and started execution (in a dedicated worker thread).
3. *executed*: the commands are being executed (a job may consist of multiple commands). Each command is documented in its own section within the job file (including result and output).
4. *finished*: all commands of the job have been executed and stored within the job file. This is the last stage for a*read-only*job.
5. *committed*: all nodes have received the changes made by this job and the new EXAConf has been synchronized. This is the last stage of a *modify*job.

Once a job is submitted, ConfD scheduler takes over and saves the result for this job at different stages and marks it as 'finished' when the task on the final stage is done. Clients which submit the job can then query the result according to the job ID at this very moment. Clients can decide what to do in this period between the submission and 'finished': either blocks for the result or execute other routines.

## Job history

ConfD jobs are carefully designed to record down all the necessary information for different stages and archive for as long as it is allowed. Whenever there is a problem found, that information can be used to reconstruct the sequence of events. The final goal is to answer the most popular question from customer support - what happened. This kind of historical information is much more accurate than any kind of description from customers. In a job file, it may contain:

* Basic job information:
	+ Job ID
	+ Intent
	+ User ID
	+ Scheduling mode
	+ Parameter list
	+ Detailed HTTP Request
* Scheduling info
* Command list and results
* Timestamps for all stages

### Remote procedure call (RPC)

RPC provides a high-level client-to-server communication for network application development. ConfD jobs also leverage modern RPC programming and support both XML and JSON for serialization/de-serialization. By implementing RPC APIs, ConfD provides the capability for remote management and automation. There are both pros and cons for XMLRPC and JSON-based RPC; the client can decide what to use. ConfD RPC removes insecure HTTP support and only listens on HTTPS. Customers have to decide whether or not to enable certificate verification on the server-side and if so, configure the SSL certification in EXAConf:


```markup
# SSL options [SSL]     # The SSL certificate, private key and CA for all EXASOL services     Cert = /exa/etc/ssl/ssl.crt     CertKey = /exa/etc/ssl/ssl.key     CertAuth = /exa/etc/ssl/ssl.ca     # Options to verify certificates: none, optional, required     CertVerify = none 
```
## Tips for executing ConfD jobs

### Get the master node at the beginning or handling HTTP_ERROR  302 (redirected)

Clients can send RPC requests to any node in the cluster but if that node is not a master node, HTTP_ERROR 302 (redirected). Either clients handle this error, or get the master node before sending out requests.


```markup
import requests # get current master IP (use any valid IP in the cluster for this request) # for example, one of the node ip is 10.10.10.11  master_ip = requests.get("https://10.10.10.11:443/master", verify = False).content.decode() # or get hostname master_name = requests.get("https://10.10.10.11:443/master?info_type=name", verify = False).content.decode() 
```
### List all RPC methods clients can call and read the help

Compared to ConfD jobs, there are only limited RPC methods available. Run 'help' will print out the description as well as arguments.


```python
import ssl from xmlrpc.client import ServerProxy  uri = f'https://{user_naem}:{password}@{master_name}:{xmlrpc_port}/rpc2' server = ServerProxy (uri, context=ssl._create_unverified_context (), allow_none = True) # get full list of the methods print (f'{server.system.listMethods ()}') # example output ['job_desc', 'job_exec', 'job_finished', 'job_help', 'job_info', 'job_list', 'job_result', 'job_start', 'job_wait', 'subscribe', 'system.listMethods', 'system.methodHelp', 'system.methodSignature', 'unsubscribe', 'user_init', 'user_login', 'user_state'] # pick one method  print (f'{server.system.methodHelp (job_start)}') # example output The main request handler - start the rpc command requested. @req, job name to be run, requested by clients @kwargs, keyword arguments passed to a specific job
```
Among the methods list above, job_exec is always a better choice when clients don't really need asynchronous handling because it combines 'job_start', 'job_wait', and 'job_result' together. Clients can get the result in just one simple call.

### List all jobs available and read the help

Jobs can be categorized into a few groups, like:

1. cluster node jobs
2. storage jobs
3. database jobs
4. storage volume jobs
5. remote volume jobs

and so on. There are too many of them but it's not necessary to remember all of them. Just check that information whenever needed.


```markup
# continue from above print (f'{server.job_list ()}') # jobs list print (f"{server.job_help ('db_create')}") # example output Description: "Create a fresh database, must not exist yet.\n\tExample: xmlrpc_connection.job_exec('db_create', {'params': \n\t\t{'db_name': 'db2', 'version': '6.1.1', 'data_volume_name': 'DataVolume1', 'owner': (1000, 1000), 'mem_size': '2048MiB', 'port': 3333, 'nodes': [11, 12], 'num_active_nodes': 2}})" Mandatory parameters: {   'data_volume_name': {   'desc': 'Volume name for EXASolution database '                                     'data.',                             'type': "(<class 'str'>,)"},     'db_name': {   'desc': 'Name of the new database.',                    'type': "(<class 'str'>,)"},     'mem_size': {   'desc': 'Amount of database memory, i.e. 2048 MiB.',                     'type': "(<class 'str'>,)"},     'nodes': {   'desc': 'List of active and reserved node ids for this '                          'database in type integer',                  'type': "<class 'list'>"},     'num_active_nodes': {   'desc': 'Number of master nodes in the database',                             'type': "<class 'int'>"},     'port': {'desc': 'Port for client connections.', 'type': "<class 'int'>"},     'version': {   'desc': 'Version of EXASolution executables.',                    'type': "(<class 'str'>,)"}} Optional parameters: {   'additional_sys_passwd_hashes': {   'desc': 'A list of password hashes for '                                                 'passwords that allow '                                                 'authentication as SYS '                                                 'independent of the SYS '                                                 'password set',                                         'type': "(<class 'str'>,)"},     'cache_volume_disk': {   'desc': 'Specify disks to use for cache: '                                      '<diskname>:<volumesize>, e.g. "disk1:7 '                                      'GiB".',                              'type': "(<class 'str'>,)"},     'cloud_data_storage': {   'desc': 'Specify cloud storage to use: '                                       's3:<awsregion>:<iothreads>:<ioconns>:<bucketname>, '                                       'e.g. "s3:eu-west-1:4:10:test1"',                               'type': "(<class 'str'>,)"},     'data_volume_id': {   'desc': 'Volume name for EXASolution database data.',                           'type': "<class 'int'>"},     'default_sys_passwd_hash': {   'desc': 'The hash used to initialize the '                                            'SYS password if a new database is '                                            'created',                                    'type': "(<class 'str'>,)"},     'enable_auditing': {   'desc': 'Enables/disables auditing for this '                                    'database system.',                            'type': "<class 'bool'>"},     'interfaces': {   'desc': 'List of network interfaces to use for database. '                               'Leave empty to use all possible network '                               'interfaces.',                       'type': "(<class 'str'>,)"},     'ldap_server': {   'desc': 'LDAP Server to use for remote database '                                'authentication, e.g. ldap[s]://192.168.16.10 . '                                'Multiple servers must be separated by commas.',                        'type': "(<class 'str'>,)"},     'master_database': {   'desc': 'Master database in case of a worker '                                    'database is being created added',                            'type': "(<class 'str'>,)"},     'owner': {   'desc': 'Tuple of (User id, group id) of the database owner '                          'in type integer.',                  'type': "(<class 'list'>, <class 'tuple'>)"},     'params': {   'desc': 'Extra parameters for startup of database.',                   'type': "(<class 'str'>,)"},     'volume_move_delay': {   'desc': 'Move failed volume nodes to used reserve '                                      'nodes automaticaly after given amount of '                                      'time, or disable it with no value.',                              'type': "<class 'int'>"},     'volume_quota': {   'desc': 'Maximal size of volume in (GiB), the database '                                 'tries to shrink it on start if required and '                                 'possible.',                         'type': "<class 'int'>"}} Substitute parameters: {'data_volume_id': ['data_volume_name'], 'data_volume_name': ['data_volume_id']} Allowed users:['root'] Allowed groups:['root', 'exaadm', 'exadbadm'] 
```
'job_help' gives more detailed descriptions to parameters as well as type info. The execution will be easier: pay attention to those mandatory parameters and choose the optional ones.

## Summary

Executing ConfD jobs is a new approach to configure and manage EXASOL Clusters. It's safer and with asynchronous mode, it's more effective both on client and server-side. Obviously, with detailed job files, it's also easier to troubleshoot; it's strongly recommended to start to use them.

