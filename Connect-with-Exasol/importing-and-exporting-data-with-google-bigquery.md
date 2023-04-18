# Importing and Exporting Data with Google Bigquery 
## Background

Google Bigquery is able to connected with Exasol via the [Simba JDBC Driver](https://cloud.google.com/bigquery/providers/simba-drivers). This article will go through how you can import and export data with Google Bigquery.  

As Google's documentation states, the JDBC driver is not designed for large volumes of data transfer between external systems and Bigquery. Internally, for EXPORTs, the data is transferred via single-row inserts and these are limited by Google to 100. Thus, exporting data via the JDBC driver is not a performant or scalable solution. IMPORTs using the JDBC driver are also not very performant due to the Simba JDBC driver limitations.

[According to Google](https://cloud.google.com/bigquery/docs/loading-data), the *recommended* way to ingest data into Bigquery is via files or Cloud Storage. Therefore, this solution make use of the Google API to load the data into a CSV file in Google Cloud Storage and then will insert the data into the target system (Bigquery or Exasol).  

## Prerequisites

Before you are able to begin loading data, you need to do the following: 

* Download the [Bigquery JDBC Driver](https://cloud.google.com/bigquery/providers/simba-drivers)
* Set up BucketFS and the accompanying buckets. Ensure that the database has access to these buckets. [More information](https://docs.exasol.com/database_concepts/bucketfs/bucketfs.htm)
* Create a Google Service Account and the accompanying private key (as a JSON file), as described [here](https://docs.exasol.com/loading_data/connect_databases/google_bigquery.htm) in step 1

## How to IMPORT Data from Google Bigquery

## Method 1: IMPORT FROM JDBC (slower)

The description on how to IMPORT data from Google Bigquery is described in detail in our [documentation portal](https://docs.exasol.com/loading_data/connect_databases/google_bigquery.htm). The instructions to follow are described in detail there. The steps are in essence:

1. Create Bigquery Service Account
2. Upload JSON key to BucketFS
3. Configure the Driver in EXAoperation
4. Create Database Connection to Google Bigquery, such as:
```markup
CREATE CONNECTION BQ_CON TO 'jdbc:bigquery://https://www.googleapis.com/bigquery/v2:443;
 ProjectId=<your-project-id>;OAuthType=0;Timeout=10000;OAuthServiceAcctEmail=<your-service-account>;
 OAuthPvtKeyPath=/d02_data/<bucketfs-service>/<bucket-name>/<your-account-keyfile>;';
```
5. You can run an IMPORT statement like below:
```markup
IMPORT INTO (C1 INT) FROM JDBC AT BQ_CON STATEMENT 'SELECT 1';
```

## Method 2: Using the script (more performant and scalable)

This solution will export the bigquery data into a CSV file stored in Google Cloud Storage via UDF using the Google API, and then will IMPORT the file into the target table in Exasol. 

### Prerequisites

* You must create an HMAC key in the Google Cloud Console that has the correct permissions to interact with Google Cloud Storage (reading/writing). You can find more information on how to do this [here](https://cloud.google.com/storage/docs/authentication/hmackeys)
* You will also need to have a Bigquery Service account. It is very likely that you already have this, because you needed it to establish the original JDBC connection to bigquery that we tested in the first place. You need to follow step 1 and 2 from this link: <https://docs.exasol.com/loading_data/connect_databases/google_bigquery.htm>
* This service account needs to have the permission to read the files from the bucket that you will specify. Please grant access to the bucket for the service account beforehand, otherwise you will receive an ACCESS DENIED error.
* The script is using Python3, so you need to have PYTHON3 running in the database (for versions > 6.2.0, this is delivered with the database).
* You need to either create a new script language container that contains the [Google Cloud python library](https://googleapis.dev/python/bigquery/latest/index.html) or upload it to BucketFS. We recommend creating a new script language container from this Github project: <https://github.com/exasol/script-languages-release>.
Since release 1.1.0 of Standard Script Language Containers ([link](https://github.com/exasol/script-languages-release/releases/tag/1.1.0)) and at least DB versions 7.0.17 and 7.1.7 ([link](https://exasol.my.site.com/s/article/Changelog-content-14476?language=en_US)) Google Cloud python library is available by default.

### Step 1 - Create Connection

Create a CONNECTION to Google Cloud Storage as described [here](https://docs.exasol.com/loading_data/load_data_google_cloud_storage_buckets.htm). You will use the credentials from the HMAC key in the CONNECTION object, like below. You should replace the bucket-name with the name of the Google Cloud Storage bucket


```markup
create connection google_cloud_storage to 'https://<bucket-name>.storage.googleapis.com' 
 user '<access key>' IDENTIFIED BY '<secret>';
```
### Step 2 - Create Scripts

Run the commands found in the [import_from_bigquery.sql](https://raw.githubusercontent.com/exasol/exa-toolbox/master/utilities/import_from_bigquery.sql) statement to create the scripts that are needed. These are stored in the ETL schema, but can be replaced and use any schema. 

### Step 3 - Execute Scripts

Once the scripts are created, you can run this command to run the Lua script which calls the UDF that was created:


```markup
execute script ETL.bigquery_import(connection_name_to_cloud_storage,file_name_in_cloud_storage,bigquery_dataset,bigquery_table,exasol_schema,exasol_table);
```
The parameters are:

* connection_name_to_cloud_storage - the name of the database connection to Google Cloud Storage. In this example, it is GOOGLE_CLOUD_STORAGE
* file_name_in_cloud_storage - the file name that will be created in Google Cloud Storage
* bigquery_dataset - the name of the dataset in Google Bigquery
* bigquery_table - the name of the table in Google Bigquery that the data should be imported from
* exasol_schema - the name of the Exasol schema that the table is in
* exasol_table - the name of the Exasol table to which data should be imported to

In my example, the call looks like this:


```markup
execute script ETL.bigquery_import('GOOGLE_CLOUD_STORAGE','test_1.csv','DATASET1','TEST1','TEST','NUMBERS');
```
## Performance Considerations

In my tests using a table containing approximately 1 million rows containing 10 columns (all integer), there was a considerable performance improvement using the script approach vs the JDBC approach:



|  |  |
| --- | --- |
| **Approach** | **Duration** |
| IMPORT FROM JDBC... | 33 Seconds |
| Script Approach | 16 Seconds |

## How to EXPORT Data to Google Bigquery

As Google's documentation states, the JDBC driver is not designed for large volumes of data transfer between external systems and Bigquery. Internally, the data is transferred via single-row inserts and these are limited by Google to 100. Thus, exporting data via the JDBC driver is not a performant or scalable solution. 

[According to Google](https://cloud.google.com/bigquery/docs/loading-data), the *recommended* way to ingest data into Bigquery is via files or Cloud Storage. Therefore, this solution will export the exasol data into a CSV file stored in Google Cloud Storage, and then will call a UDF which will transfer the data to Bigquery using the Google API. 

## Prerequisites

* You must create an HMAC key in the Google Cloud Console that has the correct permissions to interact with Google Cloud Storage (reading/writing). You can find more information on how to do this [here](https://cloud.google.com/storage/docs/authentication/hmackeys)
* You will also need to have a Bigquery Service account. It is very likely that you already have this, because you needed it to establish the original JDBC connection to bigquery that we tested in the first place. You need to follow step 1 and 2 from this link: <https://docs.exasol.com/loading_data/connect_databases/google_bigquery.htm>
* This service account needs to have the permission to read the files from the bucket that you will specify. Please grant access to the bucket for the service account beforehand, otherwise you will receive an ACCESS DENIED error.
* The script is using Python3, so you need to have PYTHON3 running in the database (for versions > 6.2.0, this is delivered with the database).
* You need to either create a new script language container that contains the [Google Cloud python library](https://googleapis.dev/python/bigquery/latest/index.html) or upload it to BucketFS. We recommend creating a new script language container from this Github project: <https://github.com/exasol/script-languages-release>.
Since release 1.1.0 of Standard Script Language Containers ([link](https://github.com/exasol/script-languages-release/releases/tag/1.1.0)) and at least DB versions 7.0.17 and 7.1.7 ([link](https://exasol.my.site.com/s/article/Changelog-content-14476?language=en_US)) Google Cloud python library is available by default.

## Step 1 - Create Connection

Create a CONNECTION to Google Cloud Storage as described [here](https://docs.exasol.com/loading_data/load_data_google_cloud_storage_buckets.htm). You will use the credentials from the HMAC key in the CONNECTION object, like below. You should replace the bucket-name with the name of the Google Cloud Storage bucket


```markup
create connection google_cloud_storage to 'https://<bucket-name>.storage.googleapis.com' 
 user '<access key>' IDENTIFIED BY '<secret>';
```
## Step 2 - Create Scripts

Run the commands found in the [export_to_bigquery.sql](https://raw.githubusercontent.com/exasol/exa-toolbox/master/utilities/export_to_bigquery.sql) statement to create the scripts that are needed. These are stored in the ETL schema, but can be replaced and use any schema. 

## Step 3 - Execute Scripts

Once the scripts are created, you can run this command to run the Lua script which calls the UDF that was created:


```markup
execute script ETL.bigquery_export(connection_name_to_cloud_storage,file_name_in_cloud_storage,bigquery_dataset,bigquery_table,exasol_schema,exasol_table);
```
The parameters are:

* connection_name_to_cloud_storage - the name of the database connection to Google Cloud Storage. In this example, it is GOOGLE_CLOUD_STORAGE
* file_name_in_cloud_storage - the file name that will be created in Google Cloud Storage
* bigquery_dataset - the name of the dataset in Google Bigquery
* bigquery_table - the name of the table in Google Bigquery that the data should be exported to
* exasol_schema - the name of the Exasol schema that the table is in
* exasol_table - the name of the Exasol table that should be exported

In my example, the call looks like this:


```markup
execute script ETL.bigquery_export('GOOGLE_CLOUD_STORAGE','test_1.csv','DATASET1','TEST1','TEST_SCHEMA','NUMBERS');
```
## Additional Notes

* If you try to run a normal EXPORT to Google Bigquery, then you may receive the following error:**[42636] ETL-5402: JDBC-Client-Error: Committing data failed: [Simba][JDBC]** **(10040) Cannot use commit while Connection is in auto-commit mode.** This is because Bigquery does not support COMMIT or ROLLBACK. A workaround can be delivered via support, but this method would still have the same pitfalls mentioned above and is not recommended.
* Google BigQuery is very sensitive to time differences, so ensure that your Exasol Environment has an NTP Server defined and that the time is synchronized. If the times are too far apart, you might see an error like **Invalid JWT: Token must be a short-lived token (60 minutes) and in a reasonable timeframe. Check your iat and exp values in the JWT claim.**
* The script does not support statements, only tables, however the Lua script can be expanded to handle exporting statements and not just tables.

## Additional References

* [Bigquery Simba Driver](https://cloud.google.com/bigquery/providers/simba-drivers)
* [Bigquery Documentation](https://cloud.google.com/bigquery/docs/loading-data)
* [CREATE CONNECTION statement](https://docs.exasol.com/sql/create_connection.htm)
* [Loading Data into Google Cloud Storage](https://docs.exasol.com/loading_data/load_data_google_cloud_storage_buckets.htm)
* [Loading Data with Bigquery](https://docs.exasol.com/loading_data/connect_databases/google_bigquery.htm)
* [CHANGELOG: Updated Script Language Container](https://exasol.my.site.com/s/article/Changelog-content-14476?language=en_US)
* [import_from_bigquery.sql](https://raw.githubusercontent.com/exasol/exa-toolbox/master/utilities/import_from_bigquery.sql)
* [export_to_bigquery.sql](https://raw.githubusercontent.com/exasol/exa-toolbox/master/utilities/export_to_bigquery.sql)


