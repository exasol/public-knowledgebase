# Docker Guide 
*Please note that this is an open source project which is not officially supported by Exasol. We will try to help you as much as possible, but can't guarantee anything since this is not an official Exasol product.* 

## Background
Exasol can be deployed as a Docker container for testing purposes. Using Docker, you can create and run an Exasol database quickly with a few commands. The underlying architecture for Exasol on Docker is not the same as traditional deployment methods on-premise and in the cloud, and for these reasons, the method of installation and administration is completely different. This guide will serve as your starting point and will link to the various articles and how-to's to install, run, administer, and troubleshoot Exasol on Docker. The list below will be continuously updated, and if you feel some information is missing or would be helpful, you can let us know by commenting on this article. 

## Installation


|  |  |
| --- | --- |
| **Article** | **Description** |
| [Install Docker on Ubuntu](https://exasol.my.site.com/s/article/Installing-Docker-Community-Edition-on-Ubuntu-Server-18-04-and-20-04) | This article describes how to install the Docker Community Edition on Ubuntu Server 18.04 and 20.04 |
| [Install Docker on Redhat & CentOS](https://exasol.my.site.com/s/article/Install-Docker-Community-Edition-on-RHEL-and-CentOS-7) | This article describes how to install the Docker Community Edition on RHEL and CentOS 7 |
| [Deploy a single-node database](https://exasol.my.site.com/s/article/How-to-deploy-a-single-node-Exasol-database-as-a-Docker-image-for-testing-purposes) | This article describes how to deploy a single-node database on Docker |



## Configuration & Maintenance


|  |  |
| --- | --- |
| **Article** | **Description** |
| [Single Node to Cluster](https://exasol.my.site.com/s/article/Docker-Single-node-to-Cluster) | This article shows you how to enlarge your single-node docker installation to two nodes |
| [Using XMLRPC to Manage your Cluster](https://exasol.my.site.com/s/article/Using-XML-RPC-to-manage-Docker-clusters) | This article shows you how you can use the XMLRPC interface to manage and perform actions on your cluster |
| [Using LVM for your Docker Container](https://exasol.my.site.com/s/article/Working-with-LVM-for-your-Docker-Container-file-device) | This article shows you how to set up LVM storage in your docker container |
| [Configure Database Parameters](https://exasol.my.site.com/s/article/Setting-a-Database-Parameter-in-a-Docker-based-Exasol-system) | This article shows you how to configure Database Parameters for Docker installations |
| [Change Docker License](https://exasol.my.site.com/s/article/Changing-the-license-file-on-a-Docker-based-Exasol-system) | This article shows you how to add or change your license file in Docker installations |
| [Add an LDAP Server](https://exasol.my.site.com/s/article/Add-an-LDAP-server-for-your-Docker-based-Exasol-Database) | This article describes how to add an LDAP server for LDAP Authentication in the database |
| [Performing Updates](https://exasol.my.site.com/s/article/Updating-a-Docker-based-Exasol-System-6-1-X-6-2-X) | This article describes how to update Docker installations from 6.1.x to 6.2.x |
| [BucketFS Management](https://exasol.my.site.com/s/article/Exasol-on-Docker-How-to-Create-a-BucketFS-and-Buckets-Inside) | This article shows you how to configure and set up BucketFS |

## Troubleshooting


|  |  |
| --- | --- |
| **Article** | **Description** |
| [Get Debug Information](https://exasol.my.site.com/s/article/How-to-get-debug-information-and-log-files-from-docker-based-systems) | This article describes how to get debug information for Docker installations |
| [Get Debug Information (Extended version); works for NGA, too](https://exasol.my.site.com/s/article/Pulling-the-Exasol-Docker-logs-works-for-NGA-too) | This article includes extra steps for those not familiar with Docker or NGA |
 

