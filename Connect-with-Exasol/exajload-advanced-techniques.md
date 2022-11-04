# EXAjload: advanced techniques 
## Background

[EXAjload](https://docs.exasol.com/loading_data/file_formats.htm?Highlight=exajload) is a standard tool for bulk data loading. Its documentation is brief, but the tool is more powerful than you might think.

It is possible to:

* import data from STDOUT of other processes without creating a tmp file on disk;
* import data from GZ-compressed streams;
* disable encryption and improve performance;
* run extra queries before or after IMPORT in the same transaction;

## Prerequisites

In order to run the examples below, let's create a basic test environment.

1. Download and install [Exasol JDBC driver](https://docs.exasol.com/connect_exasol/drivers/jdbc.htm).  
2. Download file **users.csv** attached to this article (see below).  
3. Create test schema and table.


```markup
CREATE SCHEMA exa_test;  
CREATE OR REPLACE TABLE exa_test.users 
 (     
  user_id DECIMAL(18,0),     
  user_name VARCHAR(255),     
  register_dt DATE,     
  last_visit_ts TIMESTAMP,     
  is_female BOOLEAN,     
  user_rating DECIMAL(10,5),     
  user_score DOUBLE,     
  status VARCHAR(50) 
 );
```
## IMPORT data from stream

You may IMPORT data not only from LOCAL FILE, but also from system files and pseudo-devices. It opens the possibility to read data stream from STDIN of "exajload" process. You may process data and stream it directly into exajload without creating a temporary file on disk.

Example:


```markup
cat users.csv | head -n 100 | ./exajload \
-c 'localhost:8563' \
-u 'SYS' \
-P 'exasol' \
-s 'exa_test' \
-presql 'TRUNCATE TABLE users' \
-sql 'IMPORT INTO users FROM LOCAL CSV FILE '\''/dev/stdin'\'' ROW SEPARATOR = '\''LF'\'''
```
## IMPORT data from GZ-compressed stream

It is possible to upgrade the previous example by sending compressed data stream to Exasol. It might be useful if you have slow or costly internet connection (e.g. WiFi). The amount of traffic will be reduced by factor 3-6x at the cost of extra CPU usage.

All we need to do is to "trick" Exasol into thinking that it is going to import from file with **.gz** extension. This can be achieved by creating a symlink **stdin.gz** pointing to **/dev/stdin**.


```markup
ln -s /dev/stdin stdin.gz
```
Now can we use this symlink to send a compressed data stream.

Example:


```markup
cat users.csv | head -n 200 | gzip -c | ./exajload \
-c 'localhost:8563' \
-u 'SYS' \
-P 'exasol' \
-s 'exa_test' \
-presql 'TRUNCATE TABLE users' \
-sql 'IMPORT INTO users FROM LOCAL CSV FILE '\''stdin.gz'\'' ROW SEPARATOR = '\''LF'\'''
```
## Disable encryption to improve performance

Exasol JDBC connections are encrypted by default since version 6.0+. It is "good" for security, but it actually adds a significant overhead. If you already operate in context of internal secured network, VPN or encrypted tunnel, you may disable the encryption on JDBC driver level and improve performance.

In order to do so, you should add the explicit option to JDBC connection string:


```markup
;encryption=0
```
Example:


```markup
./exajload \
-c 'localhost:8563;encryption=0' \
-u 'SYS' \
-P 'exasol' \
-s 'exa_test' \
-presql 'TRUNCATE TABLE users' \
-sql 'IMPORT INTO users FROM LOCAL CSV FILE '\''users.csv'\'' ROW SEPARATOR = '\''LF'\'''
```
You may roughly measure the performance benefit by adding **time** command at the beginning.

## Run other queries in the same transaction

It might be very useful to run other SQL commands before or after IMPORT in the same transaction. If any query fails, the whole transaction should be reverted. For example, it is possible to TRUNCATE table, IMPORT new data and run COMMIT afterwards.

In order to do so, you should disable autocommit explicitly, and call COMMIT manually using **-postsql** parameter.

Example:


```markup
./exajload \
-c 'localhost:8563;autocommit=0' \
-u 'SYS' \
-P 'exasol' \
-s 'exa_test' \
-presql 'TRUNCATE TABLE users' \
-sql 'IMPORT INTO users FROM LOCAL CSV FILE '\''users.csv'\'' ROW SEPARATOR = '\''LF'\''' \
-postsql 'COMMIT'
```
You may have any number of **-presql** and **-postsql** statements. Just make sure you always have COMMIT at the end.

## Downloads
[users.zip](https://github.com/exasol/Public-Knowledgebase/files/9935962/users.zip)

