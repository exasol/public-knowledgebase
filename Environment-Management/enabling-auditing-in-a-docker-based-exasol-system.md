# Enabling Auditing in a Docker-based Exasol system 
## Background

In this tutorial we will show you how to enable Auditing on a Docker-based Exasol system

## Prerequisites

* Access to the Docker host

## How to enable Auditing on a docker-based Exasol system

In this section we will show you how to:

1. Edit the EXAConf file and add the Auditing parameter
2. Commit the changes

### Step 1. Log in to the Docker host and edit your EXAConf file

Log in to your Docker host via ssh (or console), log in to your Exasol container:


```"lia-message-template-content-zone"
$ docker exec -it ***<your_exasol_container_name>*** /bin/bash
```
Edit the EXAConf file with your preferred text editor and add the following line to your database parameters: 


```
EnableAuditing = yes
```
The database section of your EXAConf file should look like this:


```
[DB : DB1]  
    Version = 7.0.3  
    MemSize = 2 GiB  
    Port = 8563  
    Owner = 500 : 500  
    Nodes = 11  
    **EnableAuditing = yes**  
    NumActiveNodes = 1  
    DataVolume = DataVolume1
```
### Step 2. Commit the changes

Once the changes are done, run the following command inside the container:


```
$ sed -i '/Checksum =/c\ Checksum = COMMIT' /exa/etc/EXAConf
```
If you are running a cluster then be sure to also sync the file:


```
$ cos_sync_files /exa/etc/EXAConf
```
### Step 3. Restart the container(s)

Once the changes are done, restart the container(s) on you Docker hosts


```
$ docker restart ***<your_exasol_container_name>***
```
### Step 4. Verify the parameter's value

Once the container is restarted, log in to the container and run the following command:


```
$ dwad_client list
```
The output should be similar to:

![](images/Audit_Docker.png)

