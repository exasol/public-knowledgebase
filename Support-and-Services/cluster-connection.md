# How Exasol Connects to Clusters



## General

The only people who are able to connect to your cluster are members of the Support Team. 
## Remote On-Premise Access

If Exasol Support has access to your cluster with a VPN connection, like that which is needed for [Monitoring Services](https://exasol.my.site.com/s/article/Monitoring-of-an-Exasol-Database?language=en_US), the following describes the process that Exasol Support uses to connect to your cluster.

![Cluster Connection](https://github.com/bailbot/Public-Knowledgebase/blob/main/General%20Information/Support-and-Services/cluster_connection.png)

1. Exasol's Engineers must connect to their Exasol VPN before they are able to access any support hosts. This authentication is done using their Active Directory Credentials. This ensures that even when Engineers are working from home, the connection to your cluster and any data is secure. 
2. Exasol Support can connect to your support host (jump server) using 2-factor authentication: AD password + yubikey
3. Once in the support host, Exasol Support can connect to your support host via the site-to-site VPN that is configured between the cluster and Exasol. This VPN must pass through the both the Exasol and Customer's Firewall. 
4. The passwords to connect to the cluster (if allowed) are stored in a secure password safe within the Exasol network. Only authorized support engineers have access to this password safe and they must be in the Exasol VPN and authenticate with their AD password.   

With these methods in place, we ensure that only authorized personnel have access to your cluster and all data is transmitted securely. 
## Access To Public Clouds

Access to customer public cloud providers can be granted to Exasol Support in order to execute maintenance tasks and/or cluster debug & troubleshooting activities. Exasol will not get access to the Public Cloud console.

Access to Exasol cluster is allowed through a secure VPN connection. You can find information about the exact configuration below:

- [GCP](https://exasol.my.site.com/s/article/GCP-Remote-Support-VPN?language=en_US)
- [AWS](https://exasol.my.site.com/s/article/AWS-Remote-support-VPN?language=en_US)

With this configuration, Exasol may get access to the following:

- Exasol [EXAoperation](https://docs.exasol.com/db/latest/administration/on-premise/admin_interface/exaoperation.htm) (WebUI)
- Exasol cluster access (SSH)
- Exasol database ([Debug User](https://docs.exasol.com/db/latest/planning/support.htm))

## Ad-Hoc Access

If no default access policy is defined, but Exasol Support requires access to the customer's Exasol cluster for troubleshooting and/or debugging, this can be achieved by starting an ad-hoc remote screen session. Exasol Support will never ask for tools other than WebEx and/or Zoom.
