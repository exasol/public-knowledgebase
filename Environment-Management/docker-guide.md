# Docker Guide 
*Please note that this is an open source project which is not officially supported by Exasol. We will try to help you as much as possible, but can't guarantee anything since this is not an official Exasol product.*

## Background
Exasol can be deployed as a Docker container for testing purposes. Using Docker, you can create and run an Exasol database quickly with a few commands. The underlying architecture for Exasol on Docker is not the same as traditional deployment methods on-premise and in the cloud, and for these reasons, the method of installation and administration is completely different. This guide will serve as your starting point and will link to the various articles and how-to's to install, run, administer, and troubleshoot Exasol on Docker. The list below will be continuously updated, and if you feel some information is missing or would be helpful, you can let us know by commenting on this article. 

## Installation


|  |  |
| --- | --- |
| **Article** | **Description** |
| [Install Docker on Ubuntu](https://community.exasol.com/t5/environment-management/installing-docker-community-edition-on-ubuntu-server-18-04-and/ta-p/1278) | This article describes how to install the Docker Community Edition on Ubuntu Server 18.04 and 20.04 |
| [Install Docker on Redhat & CentOS](https://community.exasol.com/t5/environment-management/install-docker-community-edition-on-rhel-and-centos-7/ta-p/1279) | This article describes how to install the Docker Community Edition on RHEL and CentOS 7 |
| [Deploy a single-node database](https://community.exasol.com/t5/environment-management/how-to-deploy-a-single-node-exasol-database-as-a-docker-image/ta-p/921) | This article describes how to deploy a single-node database on Docker |



## Configuration & Maintenance


|  |  |
| --- | --- |
| **Article** | **Description** |
| [Single Node to Cluster](https://community.exasol.com/t5/environment-management/docker-single-node-to-cluster/ta-p/1572) | This article shows you how to enlarge your single-node docker installation to two nodes |
| [Using XMLRPC to Manage your Cluster](https://community.exasol.com/t5/environment-management/using-xml-rpc-to-manage-docker-clusters/ta-p/1298) | This article shows you how you can use the XMLRPC interface to manage and perform actions on your cluster |
| [Using LVM for your Docker Container](https://community.exasol.com/t5/environment-management/working-with-lvm-for-your-docker-container/ta-p/1287) | This article shows you how to set up LVM storage in your docker container |
| [Configure Database Parameters](https://community.exasol.com/t5/environment-management/setting-a-database-parameter-in-a-docker-based-exasol-system/ta-p/1353) | This article shows you how to configure Database Parameters for Docker installations |
| [Change Docker License](https://community.exasol.com/t5/environment-management/changing-the-license-file-on-a-docker-based-exasol-system/ta-p/1341) | This article shows you how to add or change your license file in Docker installations |
| [Add an LDAP Server](https://community.exasol.com/t5/environment-management/add-an-ldap-server-for-your-docker-based-exasol-database/ta-p/1359) | This article describes how to add an LDAP server for LDAP Authentication in the database |
| [Performing Updates](https://community.exasol.com/t5/environment-management/updating-a-docker-based-exasol-system-6-1-x-gt-6-2-x/ta-p/1372) | This article describes how to update Docker installations from 6.1.x to 6.2.x |
| [BucketFS Management](https://community.exasol.com/t5/environment-management/exasol-on-docker-how-to-create-a-bucketfs-and-buckets-inside/ta-p/2368) | This article shows you how to configure and set up BucketFS |

## Troubleshooting


|  |  |
| --- | --- |
| **Article** | **Description** |
| [Get Debug Information](https://community.exasol.com/t5/environment-management/how-to-get-debug-information-and-log-files-from-docker-based/ta-p/2366) | This article describes how to get debug information for Docker installations |
| [Get Debug Information (Extended version); works for NGA, too](https://community.exasol.com/t5/database-features/pulling-the-exasol-docker-logs-works-for-nga-too/ta-p/3662) | This article includes extra steps for those not familiar with Docker or NGA |
 

