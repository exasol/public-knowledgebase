# Enable internet access for Exasol Community Edition 
## Background

By default, an Exasol virtual machine (VM) is configured to use a host-only network. This configuration allows to access the database and the EXAoperation management interface locally from the host machine. Nevertheless, this configuration prevents the use of publically available hosts and services on the internet from the virtual machine. This How-To provides information about configuring Exasol to be able to access the internet and enables users to:

* use DNS to access publicly reachable servers for making backups or in database IMPORT/EXPORT statements 
* use LDAP servers of your choice for database or EXAoperation accounts
* use standard repositories for the installation of UDF packages
* use the Exasol Version Check (only if this feature has not been disabled)

## Prerequisites

If not already done, import the Exasol OVA file into the VM tool of your choice (in Virtualbox: File -> Import Appliance). Accept the "End User License Agreement" and the "Privacy Statement" and wait until the image has been successfully loaded.

## How to enable internet access for Exasol Community Edition

## Configuration of VM network

## Step 1

Now, a new VM has been created. Change its network settings to use NAT (in Virtualbox: right click on VM -> Settings -> Network -> Adapter 1 -> Attached to NAT)

## Step 2

Define port forwardings to guest ports 8563 (database) and 443 (EXAoperation management interface) (in Virtualbox: Adapter 1 -> Port Forwarding -> Add rule -> Host Port 8563 and Guest Port 8563 -> Add rule -> Host Port 4443 and Guest Port 443). The port forwarding rules will enable you to use the VM from the physical host machine.

## Step 3

Start the VM and wait until Exasol is up and running.

##  Configuration of DNS server

## Step 1

Browse to EXAoperation and login.

## Step 2

Go to Network. In the System tab, click on "Edit".

## Step 3

Add one or two DNS servers reachable from the VM (e.g. "8.8.8.8" for an environment that can reach internet DNS servers) and click "Apply".

## Step 4

Log out.


