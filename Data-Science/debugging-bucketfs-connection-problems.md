# Debugging BucketFS Connection Problems 
## Problem

[BucketFS](https://docs.exasol.com/database_concepts/bucketfs/bucketfs.htm) is a synchronous file system that is stored directly within the cluster. It is primarily used to store small files for use in UDF scripts, such as jar files, R models, [additional script languages](https://docs.exasol.com/database_concepts/udf_scripts/adding_new_packages_script_languages.htm), and more. When working with BucketFS, the connection from BucketFS to the database does not happen automatically and may require additional configuration. This additional configuration is often forgotten.  

## Diagnosis

When referencing a file in BucketFS in any UDF script (including Virtual Schema adapter scripts), the user may get an error like this:


```markup
FileNotFoundError: [Errno 2] No such file or directory: '<invalid path>' " caught in script...
```
## Explanation

BucketFS is a separate file-system with it's own access control. Creating a bucket and then uploading files does not automatically mean that users in the database are able to access these files. This has to be given to users as well, like all other permissions. 

The above error suggests one of the below cases:

* the file is not referenced correctly in the UDF (typos, bad paths, etc.)
* The user is not able to read the files in BucketFS

## Recommendation

When confronted with this problem, we recommend the following steps to help resolve it:

## Check the filename

Within the UDF, you should check that the file is both written completely correct (file name, for example), and that it is referenced correctly. If a file is stored in BucketFS, you should reference this file using the following method:


```markup
/buckets/<bucketfs_name>/<bucket_name>/<file name>  For example: /buckets/bucketfs1/bucket1/my_file.jar
```
If you are unsure of the path you need to write, you can verify it in Exaoperation by clicking on EXABuckets -> click your bucket and view the UDF path:

![](images/Screenshot)

## Check Bucket Permissions

In the above screenshot, you can tell if the bucket is **public** or not. A Public bucket means that you do not have to enter the read password you set when you created the bucket to access the files. If the Bucket is public, you do not need any additional steps to connect to it from the database because there is no password necessary.

If the bucket **is not public,**then you also need to create a connection to the bucket to grant the database users access to the bucket. You can do this with a normal CONNECTION object in the database, like below:


```
CREATE CONNECTION my_bucket_access TO 'bucketfs:<bucketfs name>/<bucket name>'   IDENTIFIED BY 'readpw';   
--example  
CREATE CONNECTION my_bucket_access TO 'bucketfs:bfsdefault/bucket1' IDENTIFIED BY 'readpw';
```
Then, you need to grant this connection to either a user or role that needs this access, similar to any other CONNECTION object:


```markup
GRANT CONNECTION my_bucket_access TO my_user; GRANT CONNECTION my_bucket_access TO public;
```
Granting the connection to PUBLIC will allow every database user to read the files that are stored in the bucket.

## Use the LS script

You can use the below script to check exactly what your user is able to see in BucketFS from the database. It functions similar to the ls command on Linux systems:


```markup
--/ CREATE PYTHON SCALAR SCRIPT ls(my_path VARCHAR(100)) EMITS (files VARCHAR(100)) AS import subprocess  def run(c):     try:       p = subprocess.Popen('ls '+c.my_path,         stdout = subprocess.PIPE,         stderr = subprocess.STDOUT,         close_fds = True,         shell = True)       out, err = p.communicate()       for line in out.strip().split('\n'):         c.emit(line)     finally:       if p is not None:         try: p.kill()         except: pass /   SELECT ls('/buckets/bfsdefault/bucket1');
```
You can traverse the file system by starting with /buckets and checking which BucketFS's you are able to see, and then can dig deeper into the specific file. For example:


```markup
SELECT ls('/buckets');  SELECT ls('/buckets/bfsdefault');  SELECT ls('/buckets/bfsdefault/bucket1');
```
If you are able to see the file in the results, then you are also able to use that path and filename in your other UDF's

## Additional References

* <https://docs.exasol.com/database_concepts/bucketfs/bucketfs.htm>
