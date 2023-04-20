# Install SuperDoctor for SuperMicro Server via XML-RPC 
## How to install SuperDoctor for SuperMicro Server via XML-RPC

## Step 1

Upload "Plugin.Administration.SuperDoctor-5.5.0-1.0.2-2018-08-21.pkg" to EXAoperation

* Login to EXAoperation (User privilege Administrator) 
* Upload pkg **Configuration>Software>Versions>Browse>Submit**

## Step 2

Connect to EXAoperation via XML-RPC (this example uses Python)


```
>>> import xmlrpclib, pprint, base64 
>>> s = xmlrpclib.ServerProxy("http://user:password@license-server/cluster1")
```
## Step 3

Show current plugin version and plugin functions


```
>>> pprint.pprint(s.showPluginList()) 
['Administration.SuperDoctor-5.5.0-1.0.2']
```

```
>>> pprint.pprint(s.showPluginFunctions('Administration.SuperDoctor-5.5.0-1.0.2'))
{'ACTIVATE': 'Activate this plugin.',
 'DEACTIVATE': 'Deactivate this plugin.',
 'GET_SNMP_CONFIG': 'Get snmp conf',
 'INSTALL': 'Install this plugin.',
 'PUT_SNMP_CONFIG': 'Put snmp conf',
 'STATUS': 'Check service status.',
 'UNINSTALL': 'Uninstall this plugin.'}
```
## Step 4a


```
>>> sts, ret = s.callPlugin('Administration.SuperDoctor-5.5.0-1.0.2','n17','INSTALL') 
>>> ret 
'Archive:  /usr/opt/EXAplugins/Administration.SuperDoctor-5.5.0-1.0.2/packages/SD5_5.5.0_build.784_linux.zip\n  inflating: /tmp/SuperMicro/ReleaseNote.txt  \n  inflating: /tmp/SuperMicro/SSM_MIB.zip  \n  inflating: /tmp/SuperMicro/SuperDoctor5Installer_5.5.0_build.784_linux_x64_20170511162151.bin  \n  inflating: /tmp/SuperMicro/SuperDoctor5_UserGuide.pdf  \n  inflating: /tmp/SuperMicro/crc32.txt  \n  inflating: /tmp/SuperMicro/installer_agent.properties  '
```
## Step 4b


```
>>> config = base64.b64encode(open('/path/to/installer_agent.properties').read ())
>>> sts, ret = s.callPlugin('Administration.SuperDoctor-5.5.0-1.0.2','n17','INSTALL', config)
>>> ret
```
## Step 5


```
>>> sts, ret = s.callPlugin('Administration.SuperDoctor-5.5.0-1.0.2','n17','ACTIVATE')
>>> ret
'Stopping snmpd: [  OK  ]\nStarting snmpd: [  OK  ]'
```
## Step 6


```
pass  .1.3.6.1.4.1.10876  /opt/Supermicro/SuperDoctor5/libs/native/snmpagent
```
will be removed from */etc/snmp/snmpd.conf* and SNMPD will be restarted.


```
>>> sts, ret = s.callPlugin('Administration.SuperDoctor-5.5.0-1.0.2','n17','DEACTIVATE')
>>> ret
'Stopping snmpd: [  OK  ]\nStarting snmpd: [  OK  ]\nDeactived'
```
## Step 7


```
>>> f = open('/path/to/snmpd.conf','w')
>>> f.write(s.callPlugin('Administration.SuperDoctor-5.5.0-1.0.2','n17', 'GET_SNMP_CONFIG')[1])
>>> f.close()
```
## Step 8


```
>>> upload = base64.b64encode(open('/path/to/snmpd.conf').read ())
>>> sts, ret = s.callPlugin('Administration.SuperDoctor-5.5.0-1.0.2', 'n17', 'PUT_SNMP_CONFIG', upload)
>>> ret
'Reloading snmpd: [  OK  ]'
```
## Step 9


```
>>> sts, ret = s.callPlugin('Administration.SuperDoctor-5.5.0-1.0.2','n17','ACTIVATE')
>>> ret
'Stopping snmpd: [  OK  ]\nStarting snmpd: [  OK  ]'
```
## Step 10


```
>>> sts, ret = s.callPlugin('Administration.SuperDoctor-5.5.0-1.0.2','n17','STATUS')
>>> ret
'snmpd status: snmpd (pid 3711) is running...\nsuperdoctor 5 status: SuperDoctor 5 is running (45943).'
```
## Step 11


```
>>> sts, ret = s.callPlugin('Administration.SuperDoctor-5.5.0-1.0.2','n17','UNINSTALL')
>>> ret
'Uninstalled'
```

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 