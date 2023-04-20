# Manually setting time via EXAoperation 
## Background

This article guides you through the procedure of setting the time on clusters manually as preparation of configuring NTP servers ([Configuring NTP servers via EXAoperation](https://exasol.my.site.com/s/article/Configuring-NTP-servers-via-EXAoperation))

The cluster nodes constantly exchange configuration and vitality information and depend on proper time synchronization. While it is possible to manually set the time on EXASolution clusters, it is highly recommended to supply NTP servers for time synchronization.

## Prerequisites

* The update requires a maintenance window of at least half an hour.
* The tasks performed in EXAoperation requires a user with at least "Administrator" privileges.

## Procedure

## 1.1 Shutdown all database

* Open 'Services > EXASolution'
* Check the database operations. If the database is stopped while an operation is in progress the operation will be aborted
* Select all (running) EXASolution instances
* Click on the button "Shutdown"
* Reload the page until all instances change their status from "Running" to "Created"
* You may follow the procedure in an appropriate logservice:


>  System marked as stopped.  
> Successfully send retry shutdown event to system partition 64.  
> EXASolution exa_db is rejecting connections  
> controller-st(0.0): Shutdown called.  
> User 0 requests shutdown of system.
> 
>  

## 1.2 Shutdown EXAStorage Service

* Open 'Service > EXAStorage'
* Check if any operations are currently in progress (if EXAStorage is stopped while an operation is in progress, the operation will be aborted)
* Click on button "Shutdown Storage Service"
* After a successful shutdown, the EXAStorage page displays:

## 1.3 Check NTP configuration

* Open 'Configuration > Network'
* Check if there are already NTP servers configured. If **yes** please remove them by clicking on "Edit".
* Open 'Service > Monitoring'
* Change the time
* Click on "Set Cluster time"   
   Please follow the instruction of [Configuring NTP servers via EXAoperation](https://exasol.my.site.com/s/article/Configuring-NTP-servers-via-EXAoperation)  

 . See "Procedure - 1.2 Configure NTP server & 1.3 Synchronise time on the cluster"

## 1.4 Startup storage

* Navigate to the EXAoperation page Services > EXAStorage
* Ensure that all database nodes indicates the state "Running"
* Click on the button "Startup Storage Service" and confirm your choice when prompted
* After the EXAStorage page has been reloaded, check the status of all nodes, disks and volumes

## 1.5 Startup database

* Open the Services > EXASolution page and repeat the following steps for all instances:
* Click on an EXASolution instance name
* From the "Actions" dropdown menu please select "Startup" and confirm with click on the button "Submit".
* Navigate back to the Services > EXASolution page and reload until the database indicates the status "Running"
* You may follow the procedure in an appropriate logservice:


>  EXASolution exa_demo is accepting connections  
> System is ready to receive client connections.  
> System started successfully in partition 44.  
> User 0 requests startup of system.  
> User 0 requests new system setup.
> 
>  

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 