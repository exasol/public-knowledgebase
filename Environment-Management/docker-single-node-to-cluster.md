# Docker: Single node to Cluster 
## Background

Below example shows enlarging docker single node system to two nodes cluster. 

## Prerequisites

Before enlarging the single node to the cluster, make sure that you have configured the existing Exasol container to use a persistent volume. (See creating a stand-alone Exasol container section: <https://github.com/EXASOL/docker-db> )

## How to enlarge docker single node system to cluster

## Step 1

Stop the database


```
 docker exec -ti instance_name dwad_client stop-wait DB1 
```
## Step 2

Prepare all **new nodes** as described in the [multi-host section](https://github.com/EXASOL/docker-db#creating-a-multi-host-exasol-cluster) of the Github doc (incl. device file creation), but skip steps 2 and 3 (i. e. **don't modify and copy EXAConf**, it will be done later).

## Step 3

Modify EXAConf on the **old node**

* Add new node sections using the exaconf CLI tool from Github repo (also creates a UUID):

   
```
exaconf add-node /path/to/EXAConf -p 10.10.10.12/16 -n 12
```
* **Alternatively** you can copy/paste the existing node configuration for each new node and change UUID and private network manually. Without exaconf you can use hddident to create a UUID: 
```
[root@n11 /]# /usr/opt/EXASuite-6/EXAClusterOS-6.0.12/sbin/hddident -G -u new_uuid 
[root@n11 /]# cat new_uuid  
C88D5DDC4BB3135344E0120E6BAC485CD191E1BB
```
* Change ssh port from 22 -> unused port
* Give real IP address to the old node
* Change node list and redundancy for volume
* Change node list and number of master nodes for DB
* Add disk section for node n12 and create device files using e.g. truncate or dd or LVM
* Change "Checksum" value to "Commit"

## Step 4

Copy the modified EXAConf from the old node to all new nodes

## Step 5

Start docker instances on each node, it will not increase the number of database nodes. It had to be increased manually as below


```
on the first node: 
docker run --name n11 --detach --network=host --privileged -v /mnt/docker/:/exa exasol/docker-db:latest init-sc --node-id 11  

on second node:  
docker run --name n12 --detach --network=host --privileged -v /mnt/docker/:/exa exasol/docker-db:latest init-sc --node-id 12
```
## Step 6

Login to docker instance in one of the node: 


```
docker exec -ti instance_name /bin/bash 
```
## Step 7

Stop the database


```
dwad_client stop-wait DB1 
```
## Step 8

Resize the volume (Add n12 as a master node):


```
 csresize -v 0 -a -m 1 -n 12 
```
## Step 9

Insert a new node as a reserve node


```
dwad_client insert-rnode DB1 n12 
```
## Step 10

Increase number of active nodes on the database **by one active**, if you want to add multiple nodes -> repeat this command:


```
dwad_client extend-system DB1
```
## Step 11

Add DB parameters -enlargeCluster=1, append to the list of parameters. One can get list of parameters by dwad_client print-setup database_name:


```
dwad_client print-setup DB1 > db1.cfg 
sed -i '/^PARAMS:/ s/$/ -enlargeCluster=1/' db1.cfg 
dwad_client setup DB1 db1.cfg 
```
## Step 12

Start DB:


```
dwad_client start-wait DB1 
```
## Step 13

Reorganize DB

## Step 14

Increase redundancy to two  only run once otherwise redundancy will be increased to **3**:


```
csresize -i -l1 -v0
```
## Step 15

Stop the database again and remove the parameter "-enlargeCluster=1"


```
dwad_client stop-wait DB1 
dwad_client print-setup DB1 > db1.cfg 
sed -i -e s/'-enlargeCluster=1/'/g db1.cfg 
dwad_client setup DB1 db1.cfg 
dwad_client start-wait DB1
```

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 