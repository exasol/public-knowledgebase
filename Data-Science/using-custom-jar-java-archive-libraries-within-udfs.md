# Using custom JAR (Java Archive) libraries within UDFs 
## Background

If you have your own jar that you want to use in a Java UDF, this article shows you how to do this. 

## Prerequisites

* BucketFS should be configured on the cluster and accessible to the database. You can find a guide on this [here](https://docs.exasol.com/database_concepts/bucketfs/bucketfs.htm)
* The JAR file should be already created.
* Download the JAR file found at the bottom of the article if you don't have a JAR file you would like to use.

## How to use JAR libraries within UDFs

## Step 1: Upload the JAR file to BucketFS

First we need to upload the JAR file to BucketFS. We can do this either with the CURL command, or using the [BucketFS Explorer](https://github.com/exasol/bucketfs-explorer). We recommend the BucketFS Explorer because it is a graphic interface. You only need to enter your EXAoperation credentials, and drag/drop the file to the bucket of your choice. If needed, you may also need to enter the read or write passwords that you set up for the Bucket during the prerequisites phase. 

If you decide to use CURL, you can use the following command:

```
curl --user w -v -X PUT -T my-app-1.0-SNAPSHOT.jar  http://<ip_address>:<BucketFS port>/<bucket_name>/my-app-1.0-SNAPSHOT.jar 
```

There are other options as well: 

* ["bucketfs-client" application](https://github.com/exasol/bucketfs-client/blob/main/doc/user_guide/user_guide.md)
* ["bucketfs-python" library](https://exasol.github.io/bucketfs-python/user_guide/user_guide.html)

## Step 2: Verify that the file is accessible

You can use the LS script to verify that the file is accessible by the database:


```python
--/
CREATE PYTHON3 SCALAR SCRIPT ls(my_path VARCHAR(100))
EMITS (files VARCHAR(100)) AS
import subprocess

def run(c):
	try:
	  p = subprocess.Popen('ls '+c.my_path,
		stdout = subprocess.PIPE,
		stderr = subprocess.STDOUT,
		close_fds = True,
		shell = True,
		encoding = 'utf8')
	  out, err = p.communicate()
	  for line in out.strip().split('\n'):
	    c.emit(line)
	finally:
	  if p is not None:
	    try: p.kill()
	    except: pass
/
```
Once the script is created, you can run the following command to ensure that the database is able to see the file. In this example, the bucket is test1:


```sql
SELECT ls('/buckets/bucketfs1/test1'); 
```
You should see the file in the results:


```
FILES
--------------------- 
my-app-1.0-SNAPSHOT.jar
```
If you don't see the file listed, it means something went wrong. You can check the following:

* Check that the bucket name that you specified is correct
* Check that during upload there were no error messages. If you used BucketFS Explorer, you can try to re-upload it.
* Verify the read and write passwords are correct, and if needed, change them and try again.
* If your bucket is not set to PUBLIC, you must create a connection in the database with the read password that you set up while creating the bucket. You can find more information on [this page](https://docs.exasol.com/database_concepts/bucketfs/database_access.htm)

## Step 3: Modify your UDF

You can create your UDF using the code below:


```java
--/
CREATE OR REPLACE JAVA SCALAR SCRIPT HELLOWORLD() RETURNS VARCHAR(200) AS 
// Tested using Exasol 6.2.5
// This jar was generated using the following tutorial: 
// http://maven.apache.org/guides/getting-started/maven-in-five-minutes.html 
%jar /buckets/bucketfs1/test1/my-app-1.0-SNAPSHOT.jar;
import java.io.*;
import com.mycompany.app.App; 
class HELLOWORLD { 
    static String run(ExaMetadata exa, ExaIterator ctx) throws Exception { 
        ByteArrayOutputStream baos = new ByteArrayOutputStream(); 
        System.setOut(new PrintStream(baos)); 
        App.main(null); 
        return baos.toString(); } }
/

SELECT HELLOWORLD();
```
Most importantly, **you must edit your UDF to show the correct path to your file**. In my example above, the file resides in `/buckets/bucketfs1/test1`. Just replace the path to the file with the path to your own UDF. It should match the one you used in your LS script from step 2.

## Step 4: Run your UDF

Now you can run your UDF and the JAR file that you uploaded to BucketFS will be used during the execution of the UDF

## Additional Notes

* Although this example is very simple, if you want to reference any custom JAR file within a UDF, you can follow these steps. Most importantly, you can tell your UDF to use the jar file by inserting the below line at the beginning of your UDF. You could even have a UDF which *only* references a JAR file and does nothing else, like we do for Virtual Schema Adapters.
```
%jar /buckets/<bucketfs_name>/<bucket_name>/<file_name>.jar; 
```

## Additional References

* [BucketFS Instructions](https://docs.exasol.com/database_concepts/bucketfs/bucketfs.htm)
* [About UDFs](https://docs.exasol.com/database_concepts/udf_scripts.htm)
* [Details for Java UDFs](https://docs.exasol.com/database_concepts/udf_scripts/java.htm)
* ["bucketfs-client" application](https://github.com/exasol/bucketfs-client/blob/main/doc/user_guide/user_guide.md)
* ["bucketfs-python" library](https://exasol.github.io/bucketfs-python/user_guide/user_guide.html)

## Downloads

* [java_udf.sql](https://github.com/exasol/public-knowledgebase/blob/main/Data-Science/attachments/java_udf.sql)
* [my-app-1.0-SNAPSHOT.jar.zip](https://github.com/exasol/Public-Knowledgebase/files/9936846/my-app-1.0-SNAPSHOT.jar.zip)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 