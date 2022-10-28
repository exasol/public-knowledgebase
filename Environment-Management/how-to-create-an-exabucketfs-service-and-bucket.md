# How to create an EXABucketFS service and bucket 
## Background

The default bucket service contains a Container Image. The default bucket and bucket service cannot be deleted.

## Create an EXABucketFS service and bucket

## Create a new empty EXABucketFS Service

* Click on "Add"
* Select a Data Disk: Recommended default: d02_data or a dedicated data disk (d03_data, d04_data, ...). Please do not use the Operating System Disk d00_os
* TCP Listener Ports (Check your Firewall settings, Listener Port can only be used once)
	+ HTTP Port: TCP Port e.g. 8080
	+ HTTPS Port: TCP Port e.g. 8443
* Description: For the bucket service
* Click on "Add"  
   ![](images/1.png)

## Create a new empty EXABucketFS Service Bucket

One bucket service can have an arbitrary amount of buckets.

* Click on "bucketfs1"
* Click on "Add"
* Bucket Name: The name of the bucket
* Public bucket: Yes or No. Public buckets do not require a password for reading
* Read password: Read Access Password
* Write password: Write Access Password
* Description: For the bucket
* Click on "Add"  
   ![](images/2.PNG)

## Testing connectivity (write)

**PUT**  
```
curl --user w -v -X PUT -T file.tar.gz <http://10.70.0.61:8080/bucketone/file.tar.gz>  
```
**DELETE**  
```
curl --user w -v -X DELETE <http://10.70.0.61:8080/bucketone/file.tar.gz>  
```
**GET**  
```
curl --user w -v -X GET <http://10.70.0.61:8080/bucketone/file.tar.gz>
```
#### Testing connectivity (read)

**List size of all bucket objects**  
```
curl --user r -v <http://10.70.0.61:8080/bucketone/@>
```
## Additional References

<https://docs.exasol.com/administration/on-premise/bucketfs/create_new_bucket_in_bucketfs_service.htm>

