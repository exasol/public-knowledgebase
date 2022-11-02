# Install HP SPP via XML-RPC 
This article describes the process of installing HP Service Pack for ProLiant solution using XML-RPC.

#### 1. Upload "Plugin.Administration.HP-SPP-2014.09.0-0.pkg" to EXAoperation

* Login to EXAoperation (User privilege Administrator)
* Upload pkg**Configuration>Software>Versions>Browse>Submit**

#### 2. Connect to EXAoperation via XML-RPC (this example uses Python)


```
>>> import xmlrpclib, pprint 
>>> s = xmlrpclib.ServerProxy("http://user:password@license-server/cluster1") 
```
#### 3. Show plugin functions


```
>>> pprint.pprint(s.showPluginFunctions('Administration.HP-SPP-2014.09.0-0'))
{'GET_CERTIFICATE': 'Get content of specified certificate.',
 'GET_SNMP_CONFIG': 'Download current SNMP configuration.',
 'INSTALL_AND_START': 'Install and start plugin.',
 'PUT_CERTIFICATE': 'Upload new certificate.',
 'PUT_SNMP_CONFIG': 'Upload new SNMP configuration.',
 'REMOVE_CERTIFICATE': 'Remote a specific certificate.',
 'RESTART': 'Restart HP and SNMP services.',
 'START': 'Start HP and SNMP services.',
 'STATUS': 'Show status of plugin (not installed, started, stopped).',
 'STOP': 'Stop HP and SNMP services.',
 'UNINSTALL': 'Uninstall plugin.'} 
```
#### 4. Install HP SPP and check for return code


```
>>> sts, ret = s.callPlugin('Administration.HP-SPP-2014.09.0-0','n10','INSTALL_AND_START')
>>> ret
0
```
#### 5. Upload snmpd.conf (Example attached to this article)


```
>>> sts, ret = s.callPlugin('Administration.HP-SPP-2014.09.0-0', 'n10', 'PUT_SNMP_CONFIG', file('/home/user/snmpd.conf').read()) 
```
#### 6. Start HP SPP and check status.


```
>>> ret = s.callPlugin('Administration.HP-SPP-2014.09.0-0', 'n10', 'RESTART')
>>> ret
[256, '\nStopping hpsmhd: [  OK  ]\n   \n  Shutting down NIC Agent Daemon (cmanicd): [  OK  ]\n  \n  Shutting down Storage Event Logger (cmaeventd): [  OK  ]  \n  Shutting down FCA agent (cmafcad): [  OK  ]  \n  Shutting down SAS agent (cmasasd): [  OK  ]  \n  Shutting down IDA agent (cmaidad): [  OK  ]  \n  Shutting down IDE agent (cmaided): [  OK  ]  \n  Shutting down SCSI agent (cmascsid): [  OK  ]  \n  Shutting down Health agent (cmahealthd): [  OK  ]  \n  Shutting down Standard Equipment agent (cmastdeqd): [  OK  ]  \n  Shutting down Host agent (cmahostd): [  OK  ]  \n  Shutting down Threshold agent (cmathreshd): [  OK  ]  \n  Shutting down RIB agent (cmasm2d): [  OK  ]  \n  Shutting down Performance agent (cmaperfd): [  OK  ]  \n  Shutting down SNMP Peer (cmapeerd): [  OK  ]  \nStopping snmpd: [FAILED]\n  Using Proliant Standard\n \tIPMI based System Health Monitor\n  Shutting down Proliant Standard\n \tIPMI based System Health Monitor (hpasmlited): [  OK  ]  \n\nStarting hpsmhd: [  OK  ]\nStarting snmpd: [FAILED]\nCould not start SNMP daemon.\nCould not restart HP services.']
>>> ret = s.callPlugin('Administration.HP-SPP-2014.09.0-0', 'n10', 'STATUS')
>>> ret
[0, 'started']
```
#### 7. Repeat steps 4-6 for each node.

#### 8. For monitoring the HP SPP please review <https://labs.consol.de/de/nagios/check_hpasm/index.html>

[snmpd.zip](https://github.com/exasol/Public-Knowledgebase/files/9922058/snmpd.zip)
