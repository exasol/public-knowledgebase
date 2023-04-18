# Downloading database usage statistics 
Exasol logs a multitude of system information in statistical system tables (schema EXA_STATISTICS). This information is kept long-term and provides good insights concerning changes in database behavior. Many times it is easy to spot if a "system is slow" report was triggered by a sudden change or it is a long-standing trend. Those statistics also provide a good starting point for further system analysis concerning sizing and performance.

This article will describe how to generate and download the statistics in 2 ways:

a. **Manually**
1. Log into EXAoperation
2. Select your database instance
3. Select "Statistics" in the bottom pane
4. Enter valid login credentials for the database and click on "Download" (The given user must have the system privileges CREATE CONNECTION and SELECT ANY DICTIONARY)
5. When prompted by your browser, chose to save the zip-archive

b. **Automated (XML-RPC)**

The XML/RPC interface also provides a function to download these statistics. The following is a minimal parameterized example in python:


```"code-java"
s = xmlrpclib.ServerProxy(httpstring + '/cluster1') 
t = xmlrpclib.ServerProxy(httpstring + '/cluster1/' + urllib.quote_plus('db_' + dbname)) 
data = base64.b64decode(t.getDatabaseStatistics(dbuser, dbpass, startdate, enddate)) 
file(filename, 'w').write(data) 
```
The downloaded zip archive contains a set of CSV files (all unencrypted) with extracts of the most important statistical system tables.  
All data is in aggregated form, it **does not contain** any of the following:

* User names
* Schema names
* Table names
* SQL texts 
