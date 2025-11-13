# Import of DELTA files from AWS S3 fails after migration to Exasol v8

## Problem

After migration to v8, import of DELTA files from AWS S3 bucket via Cloud Storage Extension stopped working. But, import of Parquet files works as usual.
When trying to import a DELTA files from S3 we receive the following error **cannot access class sun.nio.ch.DirectBuffer**:

```sh
SQL Error [22002]: VM error: F-UDF-CL-LIB-1127: F-UDF-CL-SL-JAVA-1002: F-UDF-CL-SL-JAVA-1013:
com.exasol.ExaUDFException: F-UDF-CL-SL-JAVA-1080: Exception during run
java.lang.IllegalAccessError: class org.apache.spark.storage.StorageUtils$ (in unnamed module @0x4686afc2) cannot access class sun.nio.ch.DirectBuffer (in module java.base) because module java.base does not export sun.nio.ch to unnamed module @0x4686afc2
org.apache.spark.storage.StorageUtils$.<clinit>(StorageUtils.scala:213)
org.apache.spark.storage.BlockManagerMasterEndpoint.<init>(BlockManagerMasterEndpoint.scala:114)
org.apache.spark.SparkEnv$.$anonfun$create$9(SparkEnv.scala:358)
org.apache.spark.SparkEnv$.registerOrLookupEndpoint$1(SparkEnv.scala:295)
org.apache.spark.SparkEnv$.create(SparkEnv.scala:344)
org.apache.spark.SparkEnv$.createDriverEnv(SparkEnv.scala:196)
org.apache.spark.SparkContext.createSparkEnv(SparkContext.scala:279)
org.apache.spark.SparkContext.<init>(SparkContext.scala:464)
org.apache.spark.SparkContext$.getOrCreate(SparkContext.scala:2740)
org.apache.spark.sql.SparkSession$Builder.$anonfun$getOrCreate$2(SparkSession.scala:1026)
scala.Option.getOrElse(Option.scala:201)
org.apache.spark.sql.SparkSession$Builder.getOrCreate(SparkSession.scala:1020)
com.exasol.cloudetl.bucket.Bucket.spark$lzycompute$1(Bucket.scala:108)
com.exasol.cloudetl.bucket.Bucket.spark$1(Bucket.scala:103)
com.exasol.cloudetl.bucket.Bucket.$anonfun$createSparkSession$1(Bucket.scala:114)
com.exasol.cloudetl.bucket.Bucket.$anonfun$createSparkSession$1$adapted(Bucket.scala:111)
scala.collection.IterableOnceOps.foreach(IterableOnce.scala:576)
scala.collection.IterableOnceOps.foreach$(IterableOnce.scala:574)
scala.collection.AbstractIterator.foreach(Iterator.scala:1300)
com.exasol.cloudetl.bucket.Bucket.createSparkSession(Bucket.scala:111)
com.exasol.cloudetl.bucket.Bucket.getPathsFromDeltaLog(Bucket.scala:83)
com.exasol.cloudetl.bucket.Bucket.getPaths(Bucket.scala:78)
com.exasol.cloudetl.emitter.FilesMetadataEmitter.<init>(FilesMetadataEmitter.scala:27)
com.exasol.cloudetl.scriptclasses.FilesMetadataReader$.run(FilesMetadataReader.scala:33)
com.exasol.cloudetl.scriptclasses.FilesMetadataReader.run(FilesMetadataReader.scala)
com.exasol.ExaWrapper.run(ExaWrapper.java:215)
(Session: 1847938994977701888)
```

Import statement eample:

```sql
IMPORT INTO ECONSIGHT.DT_UCID_REGIONS_IMP
FROM SCRIPT CLOUD_STORAGE_EXTENSION.IMPORT_PATH WITH
BUCKET_PATH = 's3a://econsighttest1/data/delta/dt_ucid_regions/'
DATA_FORMAT = 'DELTA'
S3_ENDPOINT = 's3.us-east-1.amazonaws.com'
CONNECTION_NAME = 'ECONSIGHT_CONNECTION';
```

It works for DATA_FORMAT='PARQUET', but not for DELTA. In v7 this was working for both formats. No other changes were introduced.

## Solution

Starting from Java 9 some internal JDK classes (such as sun.nio.ch.*) are no longer accessible to external or unnamed modules by default. Some components in the Cloud Storage Extension indirectly use these internal classes, which triggers the access error under Java 17.

Workaround is to allow access to the required internal package by adding this JVM option in IMPORT UDFs definition:  

```sql
%jvmoption --add-exports=java.base/sun.nio.ch=ALL-UNNAMED;
```

So the workaraund is to add this jvmoption to all 3 IMPORT UDFs. Eventually they should like this:

```sql
--/
CREATE OR REPLACE JAVA SET SCRIPT IMPORT_PATH(...) EMITS (...) AS
%jvmoption --add-exports=java.base/sun.nio.ch=ALL-UNNAMED;
%scriptclass com.exasol.cloudetl.scriptclasses.FilesImportQueryGenerator;
%jar /buckets/bfsdefault/default/exasol-cloud-storage-extension-2.9.1.jar;
/

--/
CREATE OR REPLACE JAVA SCALAR SCRIPT IMPORT_METADATA(...) EMITS (
filename VARCHAR(2000),
partition_index VARCHAR(100),
start_index DECIMAL(36, 0),
end_index DECIMAL(36, 0)
) AS
%jvmoption --add-exports=java.base/sun.nio.ch=ALL-UNNAMED;
%scriptclass com.exasol.cloudetl.scriptclasses.FilesMetadataReader;
%jar /buckets/bfsdefault/default/exasol-cloud-storage-extension-2.9.1.jar;
/

--/
CREATE OR REPLACE JAVA SET SCRIPT IMPORT_FILES(...) EMITS (...) AS
%jvmoption --add-exports=java.base/sun.nio.ch=ALL-UNNAMED;
%scriptclass com.exasol.cloudetl.scriptclasses.FilesDataImporter;
%jar /buckets/bfsdefault/default/exasol-cloud-storage-extension-2.9.1.jar;
/
```

## Additional References

* [Configure Exasol IMPORT and EXPORT to work with AWS S3 bucket](/Connect-with-Exasol/configure-cxasol-IMPORT-and-EXPORT-to-work-with-AWS-S3-bucket.md)
* [Exasol Cloud Storage Extension](https://github.com/exasol/cloud-storage-extension)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
