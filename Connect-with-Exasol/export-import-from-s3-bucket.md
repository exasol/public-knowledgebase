# Configure Exasol IMPORT and EXPORT to work with AWS S3 bucket

## Background

Exasol allows you to use AWS S3 buckets in IMPORT and EXPORT statements and get data in and out of the files stored in S3. In order to do so follow the instructions below.

## Prerequisites

Decide whether to use public or secured access for your S3 bucket, and configure the bucket accordingly.

Refer to the following AWS documentation for guidance on setting up and securing your S3 bucket:  
[Policies and permissions in Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-policy-language-overview.html)  
[Examples of Amazon S3 bucket policies](https://docs.aws.amazon.com/AmazonS3/latest/userguide/example-bucket-policies.html)

Ensure you have the following in place before proceeding:

* A properly configured Amazon S3 bucket.
* Network connectivity between your Exasol database and the S3 bucket. Verify that there is a network connectivity from the Exasol nodes to the S3 bucket. You can use the curl command below to check this. The result should be either success or 403 Forbidden, which basically means that the url could be resolved but the access is secured.  
`curl -I https://<S3_BUCKET_NAME>.s3.<REGION_NAME>.amazonaws.com`

## How to setup Exasol to use AWS S3 Bucket in IMPORT and EXPORT

### Step 1

Create a connection object to access S3 bucket from the Exasol DB.

Depending on whether the bucket is public or secured you would need to provide Access Key and Access Secret.

Squred access S3 bucket:

```sql
create or replace connection s3_conn
TO 'https://vit1221-cdp.s3.eu-central-1.amazonaws.com'
USER '<YOUR_S3_Access_Key>' 
IDENTIFIED BY '<YOUR_S3_Access_Secret>';
```

Public access S3 bucket:

```sql
create or replace connection s3_conn
TO 'https://vit1221-cdp.s3.eu-central-1.amazonaws.com';
```

### Step 2

Test IMPORT/EXPORT with the specified connection by exporting and importing a dummy csv file.

EXPORT

```sql
EXPORT 
(SELECT 'test_connection' as str from dual) 
INTO CSV
AT s3_connection  
FILE 'test_file_name.csv'
WITH COLUMN NAMES
REPLACE;
```

IMPORT

```sql
SELECT * FROM (
IMPORT INTO (v VARCHAR(200)) FROM CSV
    AT S3_CONN
    FILE 'test/test_file_name.csv'
);
```

## Troubleshooting

Known issues:

### error code=400

```txt
[Code: 0, SQL State: 42636]  ETL-5106: Following error occured while writing data to external connection 
[https://vit1221-cdpp.s3.eu-central-1.amazonaws.com/test1/test_file_name.csv?uploads= failed with error code=400 after 0 bytes. 
AuthorizationHeaderMalformed: The authorization header is malformed; the region 'us-east-1' is wrong; 
expecting 'eu-central-1'] (Session: 1826489156976181248)
```

```txt
[Code: 0, SQL State: 42636]  ETL-5105: Following error occured while reading data from external connection
[https://vit1221-cdp.s3.eu-central-1.amazonaws.com/test/test_file_name.csv failed with error code=400 after 350 bytes.
AuthorizationHeaderMalformed: The authorization header is malformed;
a non-empty Access Key (AKID) must be provided in the credential.] (Session: 1829018413790265344)
```
Reasons:

* No AccessKey/AccessSecret provided when connecting to secure bucket.
* Wrong bucket name in the connection object. Check that you are using a correct bucket name in connection object.
* Connectivity issue: firewall settings, DNS resolution issues. 

### error code=403

```txt
[Code: 0, SQL State: 42636]  ETL-5106: Following error occured while writing data to external connection 
[https://vit1221-cdp.s3.eu-central-1.amazonaws.com/test1/test_file_name.csv?uploads= failed with error code=403 after 0 bytes. 
InvalidAccessKeyId: The AWS Access Key Id you provided does not exist in our records.] (Session: 1826489156976181248)

[Code: 0, SQL State: 42636]  ETL-5106: Following error occured while writing data to external connection 
[https://vit1221-cdp.s3.eu-central-1.amazonaws.com/test1/test_file_name.csv?uploads= failed with error code=403 after 0 bytes. 
SignatureDoesNotMatch: The request signature we calculated does not match the signature you provided. 
Check your key and signing method.] (Session: 1826489156976181248)
```

Reasons:

* Wrong S3 Access Key in connection object - USER clause.
* Wrong Access Secret in connection object - IDENTIFIED BY clause.

### error 404

```txt
[Code: 0, SQL State: 42636]  ETL-5106: Following error occured while writing data to external connection 
[https://vit1221-cdp.s3.eu-central-1.amazonaws.com/test1/test_file_name.csv?uploads= failed with error code=404 after 0 bytes.
Not Found
```
Reasons:

*  Incorrect url in connection object .

## Additional References

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
