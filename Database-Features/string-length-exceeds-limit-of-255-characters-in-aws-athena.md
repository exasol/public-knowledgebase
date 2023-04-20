# String length exceeds limit of 255 characters in AWS-ATHENA 
## Scope

You might face the exception `String data right truncation. String length exceeds limit of 255 characters` in AWS_ATHENA. This article will show you how to resolve this issue. 

## Diagnosis

While loading data into a table where column length is smaller than data length, you might see the following error message:


```sql
SQL Error [42636]: ETL-3003: [Column=5 Row=23] [String data right truncation. 
String length exceeds limit of 255 characters] (Session: 1714810781205312345)
```
## Explanation

The issue is caused because we map the columns according to the information we get from the JDBC driver.  
So in the case of Athena String data type, the driver reports the length 255 by default.

## Recommendation

The driver also provides a way to change this value. You need to specify the argument in the connection string. For example, if you want to set my String column's length to 1000, this would be an example connection:


```sql
CREATE OR REPLACE CONNECTION ATHENA_CONNECTION 
TO 'jdbc:awsathena://AwsRegion=eu-west-1;S3OutputLocation=s3://virtual-schemas-test-bucket-2/test/sampledb;StringColumnLength=1000' 
USER 'user' IDENTIFIED BY 'pass';
```
When you use this connection, all String columns in Virtual Schema have size 1000 instead of the default 255.

## Additional References

* <https://www.simba.com/products/Athena/doc/JDBC_InstallGuide/content/jdbc/ath/options/stringcolumnlength.htm>

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 