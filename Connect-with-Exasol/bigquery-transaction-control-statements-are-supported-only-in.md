# BigQuery: Transaction control statements are supported only in scripts or sessions 
## Scope

It is possible to read data from Google BiqQuery to Exasol using IMPORT FROM JDBC command. Steps to configure the connection are described in documentation: [Loading Data from Google BigQuery](https://docs.exasol.com/db/latest/loading_data/connect_sources/google_bigquery.htm).

However, with default settings for Simba BigQuery JDBC driver starting from version 1.3.0.1001 IMPORT FROM JDBC command might fail with error like


```"c-mrkdwn__pre"
SQL Error [ETL-5]: JDBC-Client-Error: Failed to receive MetaData:  
[Simba][BigQueryJDBCDriver](100032) Error executing query job.  
Message: Transaction control statements are supported only in scripts or sessions  
(Session: 1743494825607364608)
```
## Explanation

The error is caused by the following change in the Simba BigQuery JDBC driver:


```"c-mrkdwn__pre"
[GBQJ-566] Transaction API support     The connector now supports JDBC transaction APIs. BigQuery supports     multi-statement transactions inside a single query, or across multiple     queries, when using sessions. For more information about transactions, see:    <https://cloud.google.com/bigquery/docs/reference/standard-sql/transactions>.        To use transaction APIs, and work with transactions across multiple     queries, set the EnableSession property to 1. For more information about    sessions, see:    <https://cloud.google.com/bigquery/docs/sessions-intro>    
```
Change log: [release-notes_1.3.0.1001.txt](https://storage.googleapis.com/simba-bq-release/jdbc/release-notes_1.3.0.1001.txt)

## Recommendation

One might fix the above mentioned error by adding the following parameter to BiqQuery JDBC connection string:


```java
EnableSession=1
```
So the full connection string will look like


```java
jdbc:bigquery://https://www.googleapis.com/bigquery/v2:443;ProjectId=<your-project-id>;OAuthType=0;Timeout=10000;OAuthServiceAcctEmail=<your-service-account>;OAuthPvtKeyPath=/d02_data/<bucketfs-service>/<bucket-name>/<your-account-keyfile>;EnableSession=1;
```
## Additional References

* [Loading Data from Google BigQuery](https://docs.exasol.com/db/latest/loading_data/connect_sources/google_bigquery.htm)
* <https://storage.googleapis.com/simba-bq-release/jdbc/release-notes_1.3.0.1001.txt>
