# Install collectd via XML-RPC 
**Collectd** is a daemon that collects, transfers and stores performance data of computers and network equipment. The acquired data is meant to help maintain an overview over available resources to detect existing or looming bottlenecks. This article describes how to install collectd using XML-RPC.

#### 1. Upload "Plugin.Monitoring.collectd-5.5.0.pkg" to EXAoperation

* Login to EXAoperation (User privilege Administrator)
* Upload pkg **Configuration>Software>Versions>Browse>Submit**

#### 2. Connect to EXAoperation via XML-RPC (this example uses Python)


```
>>> import xmlrpclib, pprint 
>>> s = xmlrpclib.ServerProxy("http://user:password@license-server/cluster1") 
```
#### 3. Show plugin functions


```
>>> pprint.pprint(s.showPluginFunctions('Monitoring.collectd-5.5.0'))
{'DISABLE_ON_BOOT': 'Disable collectd on boot of node (default)',
 'ENABLE_ON_BOOT': 'Enable collectd on boot of node',
 'GET_CONFIG': 'Get collectd configuration',
 'INSTALL': 'Install collectd software',
 'PUT_CONFIG': 'Put collectd configuration',
 'START': 'Start collectd',
 'START_WEBSERVER': 'Start collectd-web on specified IP address/port, e.g. 10.50.1.10:8080',
 'STATUS': 'Retrieve status of collectd',
 'STATUS_WEBSERVER': 'Retrieve status of webserver',
 'STOP': 'Stop collectd',
 'STOP_WEBSERVER': 'Stop collectd-web',
 'UNINSTALL': 'Uninstall collectd'}
```
#### 4. Install collectd and check for return code


```
>>> sts, ret = s.callPlugin('Monitoring.collectd-5.5.0','n10','INSTALL')
>>> ret
0
```
#### 5. Upload collectd.conf (Example attached to this article)


```
>>> sts, ret = s.callPlugin('Monitoring.collectd-5.5.0', 'n10', 'PUT_CONFIG', file('/home/user/collectd.conf').read()) 
```
#### 6. Start collectd and check status.


```
>>> ret = s.callPlugin('Monitoring.collectd-5.5.0', 'n10', 'START')
>>> ret
[0, 'Starting collectd: [  OK  ]']
>>> ret = s.callPlugin('Monitoring.collectd-5.5.0', 'n10', 'STATUS')
>>> ret
[0, 'collectdmon (pid  27855) is running...']
```
#### 7. Repeat steps 4-6 for each node.

## Downloads
[collectd.zip](https://github.com/exasol/Public-Knowledgebase/files/9920847/collectd.zip)
