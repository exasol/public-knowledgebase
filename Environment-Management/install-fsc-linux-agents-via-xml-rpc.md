# Install FSC Linux Agents via XML-RPC 
## Background

Installation of FSC Linux Agents via XML-RPC

## Prerequisites

Ask at [service@exasol.com](mailto:service@exasol.com) for FSC Monitoring plugin.

## How to Install FSC Linux Agents via XML-RPC

#### 1. Upload "Plugin.Administration.FSC-7.31-16.pkg" to EXAoperation

* Login to EXAoperation (User privilege Administrator)
* Upload pkg **Configuration>Software>Versions>Browse>Submit**

#### 2. Connect to EXAoperation via XML-RPC (this example uses Python)


```
>>> import xmlrpclib, pprint 
>>> s = xmlrpclib.ServerProxy("http://user:password@license-server/cluster1")
```
#### 3. Show plugin functions


```
>>> pprint.pprint(s.showPluginFunctions('Administration.FSC-7.31-16'))
{
'INSTALL_AND_START': 'Install and start plugin.',
'UNINSTALL': 'Uninstall plugin.',
'START': 'Start FSC and SNMP services.',
'STOP': 'Stop FSC and SNMP services.',
'RESTART': 'Restart FSC and SNMP services.',
'PUT_SNMP_CONFIG': 'Upload new SNMP configuration.',
'GET_SNMP_CONFIG': 'Download current SNMP configuration.',
'STATUS': 'Show status of plugin (not installed, started, stopped).'
}
```
#### 4. Install FSC and check for return code


```
>>> sts, ret = s.callPlugin('Administration.FSC-7.31-16','n10','INSTALL_AND_START')
>>> ret
0
```
#### 5. Upload snmpd.conf (Example attached to this article)


```
>>> sts, ret = s.callPlugin('Administration.FSC-7.31-16', 'n10', 'PUT_SNMP_CONFIG', file('/home/user/snmpd.conf').read())
```
#### 6. Start FSC and check status


```
>>> ret = s.callPlugin('Administration.FSC-7.31-16', 'n10', 'RESTART')
>>> ret

>>> ret = s.callPlugin('Administration.FSC-7.31-16', 'n10', 'STATUS')
>>> ret
[0, 'started']
```
#### 7. Repeat steps 4-6 have for each node.

## Additional Notes

For monitoring the FSC agents go to <http://support.ts.fujitsu.com/content/QuicksearchResult.asp> and search for "ServerView Integration Pack for NAGIOS

## Downloads
[snmpd-min-fsc.zip](https://github.com/exasol/Public-Knowledgebase/files/9922038/snmpd-min-fsc.zip)


*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 