# Why do I get the error "Java VM cannot find '/buckets/....jar'"

## Problem

For Java-based Virtual Schemas maintained by Exasol, adapter script defines:

* JAR files to inform UDF framework where to find the libraries (JAR files) for the virtual schema and database driver. It is done via `%jar` pragma.
* Java class used during script execution. It is done via `%scriptclass` pragma.

Example:

```sql
CREATE JAVA ADAPTER SCRIPT "JDBC_ORACLE" AS
%scriptclass com.exasol.adapter.RequestDispatcher;
%jar /buckets/bfsdefault/default/vs/virtual-schema-dist-13.0.0-oracle-3.0.7.jar;
%jar /buckets/bfsdefault/default/drivers/jdbc/oracle/ojdbc10.jar;
/
```

So you uploaded all necessary files to BucketFS, but receive error like

```text
VM error:
F-UDF-CL-LIB-1125:
F-UDF-CL-SL-JAVA-1000:
F-UDF-CL-SL-JAVA-1061:
Java VM cannot find '/buckets/bfsdefault/default/drivers/jdbc/ojdbc10.jar': No such file or directory
(Session: 1839255503714910208)
```

The following solution is also generally relevant for UDFs that use the additional %jar script option, which is a command for registering and loading necessary files (such as libraries and configuration files) from BucketFS into the UDF's runtime environment.

## Explanation

Before proceeding with the solution, it is important to understand the concept of BucketFS. In the context of Java UDFs in Exasol, BucketFS plays a crucial role in storing and distributing Java libraries, JAR files, and related resources across all database nodes. For more detailed information, please refer to the official documentation: [BucketFS](https://docs.exasol.com/db/latest/database_concepts/bucketfs/bucketfs.htm).

First of all, this multi-level error stack trace with many "F-UDF-CL" error codes means that error happened during a UDF execution (see [UDF Scripts](https://docs.exasol.com/db/latest/database_concepts/udf_scripts.htm)).
The only involved UDF script here is the Adapter script, as adapter scripts are implemented as UDFs.

In the long error stack trace we find the important part:

```text
Java VM cannot find '/buckets/bfsdefault/default/drivers/jdbc/ojdbc10.jar': No such file or directory
```

Therefore, it's important to investigate why the file cannot be located, even though it was just uploaded.

## Solution

The next diagnostic step is to explore the content of BucketFS in the eyes of a UDF.
For that purpose we'll use UDF "BUCKETFS_LS" shown in <https://github.com/exasol/exa-toolbox/tree/master/utilities#bucketfs_ls>.

Step-by-step, starting from `/buckets`, we'll check if all parent folder and file itself is visible:

```sql
-- List folders/files in top-level BucketFS directory
SELECT BUCKETFS_LS('/buckets/');

-- Explore the default bucket folder
SELECT BUCKETFS_LS('/buckets/bfsdefault/');

-- Navigate into the default subdirectory
SELECT BUCKETFS_LS('/buckets/bfsdefault/default/');
-- Repeat as needed for further subfolders and files...
SELECT BUCKETFS_LS('/buckets/bfsdefault/default/drivers/jdbc/');
...
```

What can happen is that in BucketFS Service folder (say, `bfsdefault`) there is no folder visible for the Bucket (here `default`) where you uploaded the file.

According to [BucketFS](https://docs.exasol.com/db/latest/database_concepts/bucketfs/bucketfs.htm),
if Bucket is not configured as "Public", UDFs can access it only if they are granted access to it according to [Database Access in BucketFS](https://docs.exasol.com/db/latest/administration/on-premise/bucketfs/database_access.htm).
Therefore, please check if bucket is Public in the output of ConfD job [bucketfs_info](https://docs.exasol.com/db/latest/confd/jobs/bucketfs_info.htm) for the respective BucketFS Service.
If it's not, consider granting access for UDFs via [Database Access in BucketFS](https://docs.exasol.com/db/latest/administration/on-premise/bucketfs/database_access.htm) or making it Public
(reading bucket's data will be possible for everybody with network access to the respective BucketFS Service port on a data node).

Now, suppose, Bucket folder is present in the `BUCKETFS_LS` output for the respective BucketFS Service. Another possibility is that file was created in BucketFS, but has size zero.
`BUCKETFS_LS` output in that case might look like

```sql
SELECT BUCKETFS_LS('/buckets/bfsdefault/default/jars');
```

```text
SIZE_BYTES|IS_DIR|FILE_NAME |
----------+------+----------+
         0|false |myfile.jar|
```

Often it means that an error happened during file upload via HTTP(S), resulting in file been created but content not being written.
For example, one can forget a curl option during upload. curl execution succeeds (HTTP 200), but only a 0-size file is created.
In case you hit a situation with uploaded file having size 0, please try re-uploading it, **carefully reviewing** the used curl call beforehand.

### Folder vs. file

Another similar kind of problem that one can face when uploading files to BucketFS is `curl`'s folder vs. file behavior.

Imagine the goal is still to upload file `myfile.jar` to BucketFS folder `/buckets/bfsdefault/default/jars/`.

Originally, there is no such file and folder:

```sql
WITH
content_of_default as(
  SELECT
    exa_toolbox.bucketfs_ls('/buckets/bfsdefault/default/')
)
select
  *
from
  content_of_default d
where
  1=1
  and d.file_name like '%jars%'
;
```

```text
SIZE_BYTES|IS_DIR|FILE_NAME|
----------+------+---------+
```

Then you successfully upload file

```shell
# curl -v -k --upload-file myfile.jar https://w:<write password>@<data node ip>:<BucketFS Service port>/default/jars
...
< HTTP/1.1 200 OK
...
```

However, virtual schema creation fails with "Java VM cannot find" error.

Here the problem is with the lack of the trailing slash ("/") at the end of `curl` target: by design of `curl` upload to `https://w:<write password>@<data node ip>:<BucketFS Service port>/default/jars` creates and populates file "jars" in folder "default",
while upload to `https://w:<write password>@<data node ip>:<BucketFS Service port>/default/jars/` means upload file with original name "myfile.jar" to existing folder "jars". For the latter case BucketFS backend creates the respective folder automatically
(moreover, creating folders without files in BucketFS via HTTP(S) is not possible).

So now you have a file "jars" residing in folder "default" and having content of the file "myfile.jar" to be uploaded:

```sql
-- List all entries in the 'default' bucket where the file name contains 'jars', using the BUCKETFS_LS UDF for inspection.
WITH
content_of_default as(
  SELECT
    exa_toolbox.bucketfs_ls('/buckets/bfsdefault/default/')
)
select
  *
from
  content_of_default d
where
  1=1
  and d.file_name like '%jars%'
;
```

```text
SIZE_BYTES|IS_DIR|FILE_NAME|
----------+------+---------+
         6|false |jars     |
```

If you try now to upload the file the right way

```shell
curl -v -k --upload-file myfile.jar https://w:<write password>@<data node ip>:<BucketFS Service port>/default/jars/
```

the command either doesn't return or succeeds (HTTP/1.1 200 OK). However, virtual schema creation still fails with "Java VM cannot find" error.

Here, "jars" remained a file (note IS_DIR=false):

```text
SIZE_BYTES|IS_DIR|FILE_NAME|
----------+------+---------+
         6|false |jars     |
```

as BucketFS backend couldn't turn an existing file "jars" to a folder to upload file "myfile.jar" to that folder.

What you need to do is to remove the "jars" file

```shell
curl -v -k --request DELETE https://w:<write password>@<data node ip>:<BucketFS Service port>/default/jars
```

and then repeat the upload

```shell
curl -v -k --upload-file myfile.jar https://w:<write password>@<data node ip>:<BucketFS Service port>/default/jars/
```

## Additional References

* [Virtual Schemas](https://docs.exasol.com/db/latest/database_concepts/virtual_schemas.htm)
* [BucketFS](https://docs.exasol.com/db/latest/database_concepts/bucketfs/bucketfs.htm)
* [UDF Scripts](https://docs.exasol.com/db/latest/database_concepts/udf_scripts.htm)
* [Database Access in BucketFS](https://docs.exasol.com/db/latest/administration/on-premise/bucketfs/database_access.htm)
* [bucketfs_ls UDF](https://github.com/exasol/exa-toolbox/tree/master/utilities#bucketfs_ls)
[Exasol UDF Script Options: User Documentation](https://github.com/exasol/script-languages-release/blob/master/doc/user_guide/script_options/script_options.md)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
