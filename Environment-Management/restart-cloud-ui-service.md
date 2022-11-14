# How to Restart the Cloud UI Service

## Question
Recently, we performed an update within our Exasol-AWS-hosted installation from Cloud UI Back-end Plug-in V.1.1.3 to V.1.1.4, following the provided instructions (for the XML RPC option) available under:

https://docs.exasol.com/administration/aws/plugin/cloud_ui_plugin.htm#UpdatingthePlugin

Although (as per ExaOperation) the update was successful, the Cloud UI is not available / working anymore ever since, displaying a 404 error message.

## Answer
You can restart the Cloud UI service and Exaoperation.

In order to restart the Cloud UI service you can use one of these options below:

1. Restart it via XML-RPC call
```
#!/usr/bin/python3.6

import ssl  
import xmlrpc.client  
server = xmlrpc.client.ServerProxy  
('https://admin:<password>@<ip_or_dns>/cluster1', context=ssl._create_unverified_context())  
#Test if the Plugin was uploaded correctly  
server.showPluginList()  
--['Cloud.UIBackend-1.1.3']  
server.callPlugin('Cloud.UIBackend-1.1.3', 'n0010', 'RESTART', '')
```
2. If the XML-RPC call does not work please try to restart it from systemd. Login to the license (management) server via SSH and run "systemctl restart cloudui" command.

After restarting the Cloud UI service please restart the Exaoperation service. You can do this via Exaoperation WEB UI in Exaoperation, then Restart.