# Install Protegrity via XML-RPC 
## Background

Installation of Protegrity via XML-RPC

## Prerequisites

Ask at [service@exasol.com](mailto:service@exasol.com) for Protegrity plugin.

  
## How to Install Protegrity via XML-RPC

#### 1. Upload "Plugin.Security.Protegrity-6.6.4.19.pkg" to EXAoperation

* Login to EXAoperation (User privilege Administrator)
* Upload pkg **Configuration>Software>Versions>Browse>Submit**

#### 2. Connect to EXAoperation via XML-RPC (this example uses Python)

Following code block is ready to copy and paste into a python shell:


```
from xmlrpclib import Server as xmlrpc from ssl import _create_unverified_context as ssl_context from pprint import pprint as pp from base64 import b64encode import getpass server = raw_input('Please enter IP or Hostname of Licenze Server:') ; user = raw_input('Enter your User login: ') ; password = getpass.getpass(prompt='Please enter Login Password:') server = xmlrpc('https://%s:%s@%s/cluster1/' % (user,password,server) , context = ssl_context()) 
```
#### 3. Show installed plugins


```
>>> pp(server.showPluginList()) ['Security.Protegrity-6.6.4.19'] 
```
#### 4. Show plugin functions


```
>>> pp(server.showPluginFunctions('Security.Protegrity-6.6.4.19')) 'INSTALL': 'Install plugin.', 'UPLOAD_DATA': 'Upload data directory.', 'UNINSTALL': 'Uninstall plugin.', 'START': 'Start pepserver.', 'STOP': 'Stop pepserver.', 'STATUS': 'Show status of plugin (not installed, started, stopped).' 
```
#### 5. For further usage we store the plugin name and the node list in variables:


```
>>> pname = 'Security.Protegrity-6.6.4.19' >>> nlist = server.getNodeList() 
```
#### 6. Install the plugin


```
>>> pp([[node] + server.callPlugin(pname, node, 'INSTALL', '') for node in nlist]) [['n0011', 0, ''], ['n0012', 0, ''], ['n0013', 0, ''], ['n0014', 0, '']] 
```
#### 7. Get the plugin status on each node:


```
>>> pp([[node] + server.callPlugin(pname, node, 'STATUS', '') for node in nlist]) [['n0011', 0, 'stopped'],  ['n0012', 0, 'stopped'],  ['n0013', 0, 'stopped'],  ['n0014', 0, 'stopped']] 
```
#### 8. Start plugin on each node:


```
>>> pp([[node] + server.callPlugin(pname, node, 'START', '') for node in nlist]) [['n0011', 0, 'started'],  ['n0012', 0, 'started'],  ['n0013', 0, 'started'],  ['n0014', 0, 'started']] 
```
#### 9. Push ESA config to nodes, server-side task

* Client Port (pepserver) is listening on TCP 15700

## Additional Notes

-

## Additional References

-

