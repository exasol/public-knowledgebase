# Accessing IBM Spectrum Scale Storage 
## Background

Spectrum Scale, previously known as General Parallel File System (GPFS), is a high-performance clustered file system software developed by IBM. It offers a parallel high-performance solution for many data related challenges with global file and object data access for managing data at scale.

In this article, we are going to show how to import data into a table or create a Virtual Schema over data stored in Spectrum Scale using its S3 API. For that, we are going to use Exasol's [Cloud Storage Extension](https://github.com/exasol/cloud-storage-extension) and [S3 Document Files Virtual Schema](https://github.com/exasol/s3-document-files-virtual-schema) integration projects.

## Prerequisites

* You'll need to setup IBM Spectrum Scale cluster
* You can use the Vagrant based solution provided on Github, <https://github.com/IBM/SpectrumScaleVagrant/>
* It allows you to setup Spectrum Scale on KVM/Libvirt, VirtualBox and Amazon Web Services (AWS)
* You'll need to setup an Exasol database
* Prepare cloud-storage-extension [deployment scripts](https://github.com/exasol/cloud-storage-extension/blob/main/doc/user_guide/user_guide.md#deployment)
* Prepare s3-document-files-virtual-schema [deployment scripts](https://github.com/exasol/s3-document-files-virtual-schema/blob/main/doc/user_guide/user_guide.md#installation)
* Make sure there is network connectivity between the two clusters

## Enable Spectrum Scale S3 API

After setting up the Spectrum Scale cluster, you need to enable the S3 API access.

First, please note down the Cluster Export Services (CES) IPv4 address, we are going to use it as a S3 endpoint during the import. Then, run the following command to enable the S3 API for object storage.

`sudo mmobj config change --ccrfile "proxy-server.conf" --section "filter:s3api" --property "location" --value "us-east-1"`

Make sure that you use "**us-east-1**" as location value. This is required since **us-east-1** is used as a default region when setting up S3 with custom endpoints. Starting from Spectrum Scale Object 5.1.x and later versions this region is set by default.

## Import Data From Spectrum Scale Using S3 API

In this section we are going to show you how to import Parquet formatted data from Spectrum Scale Object Storage using Exasol [cloud-storage-extension](https://github.com/exasol/cloud-storage-extension).

Create an Exasol table corresponding to the Parquet schema:


```sql
CREATE TABLE SALES_POSITIONS 
 (   
  SALES_ID       INTEGER,   
  SALES_POSITION DECIMAL(4,0),   
  PRODUCT_ID     DECIMAL(6,0),   
  PRODUCT_PRICE  DECIMAL(9,2),   
  AMOUNT         DECIMAL(2,0),   
  EXA_ROW_ROLES  DECIMAL(20, 0) 
 );
```
 Create a connection object that encodes the username and password as S3 access and secret keys:


```sql
CREATE OR REPLACE CONNECTION S3_CONNECTION TO '' USER '' IDENTIFIED BY 'S3_ACCESS_KEY=testuser;S3_SECRET_KEY=zPassw0rd1';
```
Run the import SQL statement:


```sql
IMPORT INTO RETAIL.SALES_POSITIONS FROM SCRIPT ETL.IMPORT_PATH WITH   
BUCKET_PATH              = 's3a://parquet-test-data/*.parquet'   
DATA_FORMAT              = 'PARQUET'   
S3_ENDPOINT              = 'http://172.31.21.23:8080'   
CONNECTION_NAME          = 'S3_CONNECTION'   
PARALLELISM              = 'nproc()';
```
The `S3_ENDPOINT` parameter should point to the CES IPv4 address of Spectrum Scale.

## Create Virtual Schema Over Data in Spectrum Scale

Similarly, you can create a Virtual Schema (VS) over data stored in Spectrum Scale using the S3 API.

In this guide, I am going to create a VS over [JSON Lines](https://jsonlines.org) data. First we need to create a mapping file and upload it to  Exasol's BucketFS bucket.


```json
{
  "$schema": "https://schemas.exasol.com/edml-1.2.0.json",
  "source": "test.jsonl",
  "destinationTable": "LINES",
  "description": "Maps JSON Data Lines to Exasol LINES VS table",
  "addSourceReferenceColumn": true,
  "mapping": {
    "fields": {
      "id": {
        "toVarcharMapping": {
        }
      }
    }
  }
}
```
You can read more about EDML schema mapping in S3 VS files [user guide, Defining the Schema Mapping](https://github.com/exasol/s3-document-files-virtual-schema/blob/main/doc/user_guide/user_guide.md#defining-the-schema-mapping).

Now we can create a VS over JSON Lines data stored Spectrum Scale:


```sql
CREATE OR REPLACE CONNECTION S3_VS_CONNECTION    
TO 'http://jsonlines-test-data.s3.us-east-1.172.31.21.23:8080/'    
USER 'admin'    
IDENTIFIED BY 'Passw0rd';  

CREATE VIRTUAL SCHEMA FILES_VS_TEST USING ADAPTER.S3_FILES_ADAPTER WITH     
CONNECTION_NAME = 'S3_VS_CONNECTION'     
SQL_DIALECT     = 'S3_DOCUMENT_FILES'     
MAPPING         = '/buckets/bfsdefault/schemamapping/jsonl-mapping.json';
```
As you can see, in the address of the connection object, we use custom endpoint from Spectrum Scale Object Storage.

You should be able to query data using the `LINES` table in `FILES_VS_TEST` Virtual Schema.


```sql
SELECT * FROM FILES_VS_TEST.LINES LIMIT 10;
```
## Conclusion

By following the steps shown in this guide, you can easily import Avro, Parquet or Orc formatted data from IBM Spectrum Scale object storage. Similarly, you can use [Virtual Schema S3 Document Files](https://github.com/exasol/s3-document-files-virtual-schema) integration to create a Virtual Schema over JSON or JSONLine files stored in Spectrum Scale.

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 