# Install DELL OMSA 8.1 via XML-RPC 
This article describes how to install Dell's OpenManage Server Administration solution via XML-RPC.

#### 1. Upload "Plugin.Administration.DELL-OpenManage-8.1.0.pkg" to EXAoperation

* Login to EXAoperation (User privilege required - Administrator)
* Upload pkg: **Configuration>Software>Versions>Browse>Submit**

#### 2. Connect to EXAoperation via XML-RPC (this example uses Python)


```
>>> import xmlrpclib, pprint 
>>> s = xmlrpclib.ServerProxy("http://user:password@license-server/cluster1") 
```
#### 3. Show plugin functions


```
>>> pprint.pprint(s.showPluginFunctions('Administration.DELL-OpenManage-8.1.0'))
{'GET_SNMP_CONFIG': 'Download current SNMP configuration.',
 'INSTALL_AND_START': 'Install and start plugin.',
 'PUT_SNMP_CONFIG': 'Upload new SNMP configuration.',
 'RESTART': 'Restart HP and SNMP services.',
 'START': 'Start HP and SNMP services.',
 'STATUS': 'Show status of plugin (not installed, started, stopped).',
 'STOP': 'Stop HP and SNMP services.',
 'UNINSTALL': 'Uninstall plugin.'}
```
#### 4. Install DELL OMSA and check for return code


```
>>> sts, ret = s.callPlugin('Administration.DELL-OpenManage-8.1.0','n10','INSTALL_AND_START')
>>> ret
0
```
#### 5. Upload snmpd.conf (Example attached to this article)


```
>>> sts, ret = s.callPlugin('Administration.DELL-OpenManage-8.1.0', 'n10', 'PUT_SNMP_CONFIG', file('/home/user/snmpd.conf').read()) 
```
#### 6. Restart OMSA and check status.


```
>>> ret = s.callPlugin('Administration.DELL-OpenManage-8.1.0', 'n10', 'RESTART')
>>> ret
[0, '\nShutting down DSM SA Shared Services: [  OK  ]\n\n\nShutting down DSM SA Connection Service: [  OK  ]\n\n\nStopping Systems Management Data Engine:\nStopping dsm_sa_snmpd: [  OK  ]\nStopping dsm_sa_eventmgrd: [  OK  ]\nStopping dsm_sa_datamgrd: [  OK  ]\nStopping Systems Management Device Drivers:\nStopping dell_rbu:[  OK  ]\nStarting Systems Management Device Drivers:\nStarting dell_rbu:[  OK  ]\nStarting ipmi driver: \nAlready started[  OK  ]\nStarting Systems Management Data Engine:\nStarting dsm_sa_datamgrd: [  OK  ]\nStarting dsm_sa_eventmgrd: [  OK  ]\nStarting dsm_sa_snmpd: [  OK  ]\nStarting DSM SA Shared Services: [  OK  ]\n\ntput: No value for $TERM and no -T specified\nStarting DSM SA Connection Service: [  OK  ]\n']
>>> ret = s.callPlugin('Administration.DELL-OpenManage-8.1.0', 'n10', 'STATUS')
>>> ret
[0, 'dell_rbu (module) is running\nipmi driver is running\ndsm_sa_datamgrd (pid 760 363) is running\ndsm_sa_eventmgrd (pid 732) is running\ndsm_sa_snmpd (pid 755) is running\ndsm_om_shrsvcd (pid 804) is running\ndsm_om_connsvcd (pid 850 845) is running']
```
#### 7. Repeat steps 4-6 for each node.

#### 8. For monitoring DELL OMSA please review <http://folk.uio.no/trondham/software/check_openmanage.html>

## Downloads
[snmpd.zip](https://github.com/exasol/Public-Knowledgebase/files/9921941/snmpd.zip)
