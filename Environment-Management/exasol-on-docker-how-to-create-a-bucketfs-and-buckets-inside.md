# Exasol on Docker - How to Create a BucketFS and Buckets Inside 
## Background

In this tutorial we are going to show you how to create a BucketFS and Buckets inside it for Exasol on Docker.

## Prerequisites

* Access to the Docker host
* Access to firewall/cloud management console to open port (in our example, **AWS** will be used)
* Very basic knowledge of the ***curl*** command

## How to create a BucketFS and Buckets inside it

In this section, we will show you the whole process of:

1. Creating a BucketFS
2. Creating a bucket inside it
3. (Optional) Opening the required port(s) in the AWS management console for newly created BucketFS
4. Committing the Changes
5. Uploading some files via the ***curl*** command

### Step 1. Go to your Docker host, log in to the container and create a BucketFS

 Log in to your host via ssh (or console) and get inside your Exasol on Docker container:
```"lia-message-template-content-zone"
$ docker exec -it <your exasol container name> /bin/bash
```
You can find the container's name by running ***docker ps***. Once inside the container run the following command to create a BucketFS:


```
$ exaconf add-bucketfs --name <new bucket name> --http-port <port for communicating via HTTP> --https-port <port for communicating via HTTPS> --owner 500:500
Example:
$ exaconf add-bucketfs --name newbucketfs --http-port 6932 --https-port 0 --owner 500:500
```
###### ** - This will be the name of your new BucketFS*

###### *** - This will be the port for communicating via HTTP*

###### **** - This will be the port for communicating via HTTPS*

This will create the BucketFS config required in the **/exa/etc/EXAConf** file.

### Step 2. Create a bucket inside your newly created BucketFS

Once the BucketFS is created run the following command to create the bucket inside the aforementioned BucketFS:


```
$ exaconf add-bucket --name ***newbucketfs-bucket**** --bfs-name ***newbucketfs***** --read-passwd $(echo -n "***newread***"*** | base64) --write-passwd $(echo -n "***newwrite***"**** | base64)
```
###### ** - This will be the name of your new Bucket*

###### *** - This is the name of your newly created BucketFS*

###### **** - This will be your new password for read (r)*

###### ***** - This will be your new password for write (w)*

Once the bucket is created, open the **/exa/etc/EXAConf** file and check if you can see the newly added BucketFS/Bucket there:


```
$ cat /exa/etc/EXAConf
```
Output should be similar to:

![](images/BFS_1.PNG)

### Step 3. (Optional) Open the firewall port for the new BucketFS (in this example, AWS)

Go to the Security Group that you used while deploying the Docker node and add the port that you used for the new BucketFS:

![](images/BFS_2.png)

1 - Go to the Secuirty Group and edit the inbound rules

2 - When in the security group rules' configuration press **Add Rule**

3 - Select **Custom TCP** add the port number and the source address

4 - Save the changes

If you are using an other cloud provider please check their documentation on how to open ports for services.

### Step 4. Committing the Changes

Once the changes are done, run the following command inside the container:


```
$ sed -i '/Checksum =/c\ Checksum = COMMIT' /exa/etc/EXAConf
```
Once that is done, run the following command:


```
$ exaconf commit
```
Once the commit is done your new bucket should be available via the ***curl***command.

### Step 5. Using the *curl* command to upload/download/delete

To upload a file via curl use:


```
$ curl -X PUT -T testfile.jar http://w:newwrite@***<docker_host_ip>***:6932/newbucketfs-bucket/testfile.jar
```
To delete a file via curl use:


```
$ curl -X DELETE http://w:newwrite@34.243.141.132:6932/newbucketfs-bucket/testfile.jar
```
To list the contents of the bucket:


```
$ curl http://r:newread@***<docker_host_ip>***:6932/newbucketfs-bucket/
```
