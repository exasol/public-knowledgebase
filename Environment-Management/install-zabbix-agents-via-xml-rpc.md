# Install Zabbix Agents via XML-RPC 
## How to install Zabbix Agents via XML-RPC

## Step 1

Upload Plugin.Administration.Zabbix-3.0.10-1.0.0-2018-09-25.pkg to EXAoperation

* Login to EXAoperation (User privilege Administrator)
* Upload pkg **Configuration>Software>Versions>Browse>Submit**

## Step 2

Connect to EXAoperation via XML-RPC (this example uses Python)

We suggest to use an interactive python session to install this plugin. Just copy the following snippet, fill out "userName", "password" and "hostName" and post it directly into your interactive session.


```
import ssl
from urllib         import quote_plus
from xmlrpclib      import ServerProxy
from pprint 		import pprint

userName = "admin"
password = "admin"
hostName = "10.0.0.10"

def XmlRpcCall(urlPath = ''):
    url = 'https://%s:%s@%s/cluster1%s' % (quote_plus(userName), quote_plus(password), hostName, urlPath)
    if hasattr(ssl, 'SSLContext'):
        sslcontext = ssl.SSLContext(ssl.PROTOCOL_TLSv1_2)
        sslcontext.verify_mode = ssl.CERT_NONE
        sslcontext.check_hostname = False
        return ServerProxy(url, context=sslcontext)
    else:
        return ServerProxy(url)

cluster = XmlRpcCall('/')
```
## Step 3

Show plugin functions


```
>>> cluster.showPluginList()
['Administration.Zabbix-3.0.10-1.0.0']
>>> pprint(cluster.showPluginFunctions('Administration.Zabbix-3.0.10-1.0.0'))
{'INSTALL': 'Install and start Zabbix agent',
 'READ_CONF': 'Read /etc/zabbix/zabbix_agentd.conf configuration file',
 'RESTART': 'Restarts Zabbix agent',
 'START': 'Start Zabbix agent manually',
 'STOP': 'Stop Zabbix agent manually',
 'UNINSTALL': 'Uninstall Zabbix agent',
 'WRITE_CONF': 'Write /etc/zabbix/zabbix_agentd.conf configuration file'}
```
## Step 4


```
>>> for node in cluster.getNodeList():
...     status, ret = cluster.callPlugin('Administration.Zabbix-3.0.10-1.0.0', node, 'INSTALL')
...     print node, ret
...  
```
## Step 5


```
>>> config = file('your/local/machine/zabbix_agentd.conf').read()
>>> for node in cluster.getNodeList():
...     status, ret = cluster.callPlugin('Administration.Zabbix-3.0.10-1.0.0', node, 'WRITE_CONF', config)
...     print node, status
```
## Step 6


```
>>> config = file('your/local/machine/zabbix_agentd.conf').read()
>>> for node in cluster.getNodeList():
...     status, ret = cluster.callPlugin('Administration.Zabbix-3.0.10-1.0.0', node, 'RESTART')
...     print node, status 
```
