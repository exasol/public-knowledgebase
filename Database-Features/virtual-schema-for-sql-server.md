# Virtual Schema for SQL Server 
## Background

Wouldn't it be great if we could execute a query in Exasol that reads your SQL Server database and presents the data as if it resided in Exasol? 

The **SQLServer Virtual Schema** provides an abstraction layer that makes an external [Microsoft SQL Server](https://www.microsoft.com/en-us/sql-server/sql-server-2017) database accessible from an Exasol database through regular SQL commands. This article is an extension of our [Github documentation](https://github.com/exasol/sqlserver-virtual-schema/blob/main/doc/user_guide/sqlserver_user_guide.md) and is written for a SQL Server user who is new to Exasol, to have a step-by-step guide for finding the drivers, setting up the Virtual Schema framework, and ensuring we have a successful connection to SQL Server.

### So what is a Virtual Schema and how does it work?

* Similar to a Linked Server in SQL Server
* Serves as an abstraction layer
* Allows the user to query the schema objects like regular Exasol objects (no special syntax required).
* All your queries will be Exasol queries, the virtual schema does the translation to another database dialect. The translation comes from the virtual schema adapter – not from the regular drivers.
* When the user executes a query in the Exasol database, the virtual schema adapter is started and does the syntax conversions.
* The virtual schema adapter sends back IMPORT statements with the translated query.
* Behind the scenes, data is IMPORTED into Exasol by executing the IMPORT statement from the previous step.

### What are the use cases and advantages of a Virtual Schema?

* No need to copy the data persistently – Exasol remains a single entry point.
* The data is not persisted, so it’s a runtime process.
* Can use regular Exasol SQL syntax – Easier to write joins.
* No need to write complex statements.
* No need to worry about data type conversions.
* Database users are usually good at writing SQL code. What would be more convenient than reusing those skills?
* Our data analytics platform is massively parallel software. The Virtual Schemas are designed to use parallel access to sources which support this.

## Prerequisites

You will need:

1. A computer with access to the internet.
2. Access to the EXASolution UI - the Exasol GUI for managing Exasol. You can find it using the URL: [HTTPS://<your-exasol-server>:443](HTTP://<your-server>:443). If you are using the community edition,  the credentials are "admin" / "admin".
3. Access to a SQL Server instance. If you are able to connect to SQL Server and see tables in a database using the SQL Server Management Studio, you are all set. The point is that you have valid SQL Server credentials.

## How to set up a Virtual Schema for SQL Server

## Step 1

As always we suggest starting with our documentation, to at least familiarize yourself with what to expect. We can start here at [virtual_schemas](https://docs.exasol.com/database_concepts/virtual_schemas.htm?Highlight=virtual%20schema).

## Step 2

Download the proper JDBC driver by Microsoft. Our example is using the [mssql-jdbc-9.2.0.jre8.jar](https://github.com/microsoft/mssql-jdbc/releases/download/v9.2.0/mssql-jdbc-9.2.0.jre8.jar). If the downloads are updated with more current releases, look for the *jre8.jar file. The website for the SQL Server JDBC drivers we are using is [mssql-jdbc/releases](https://github.com/microsoft/mssql-jdbc/releases). If you are using a more recent one, look for the *jre8.jar file.

Once you have found the appropriate *jre8.jar file, click on it to start the download to your computer. 

## Step 3

Upload the JDBC driver to Exasol.

**a.** Open a web-browser and navigate to <HTTPS://<your-exasol-server>:443>. If you are using a VM, then refer to the port mapping to find the forwarded port, and use that in your HTTP connection. Here is an example from running Exasol on VirtualBox and it uses port forwarding. 

![](images/1_Port_Forwarding.png)

Our example accesses the Exasol UI with the URL <https://localhost:4443/>.

**b.** Navigate to the "Software" page.

![](images/2_EXASolution_main_menu_showing_Software.png)

**c**. Choose the "JDBC Drivers" panel.

![](images/3_Software_to_JDBC_Drivers.png)

**d**. Click "Add" to create a new JDBC entry.

![](images/4_jdbc_add.png)

**e.** Define the new driver.

Here we see the JDBC driver settings box, you can find more information here at [sqlserver_user_guide.](https://github.com/exasol/sqlserver-virtual-schema/blob/main/doc/user_guide/sqlserver_user_guide.md)

![](images/5_jdbc_settings.png)

If you want to copy and paste, here are the values:

**Driver Name: SQLSERVER**

**Main Class: com.microsoft.sqlserver.jdbc.SQLServerDriver**

**Prefix:** **jdbc:sqlserver:**

Don't forget to check the **Disable Security Manager** box. The reason is that the JDBC driver requires a particular JAVA permission which we do not grant by default.

**f.** Click "Add" to save your settings inside Exasol JDBC drivers. This will take you back to the "JDBC DRIVERS" menu. 

**g.** Find your new entry in the menu and select it by choosing the radio button on the left.

![](images/6_choose_new_jdbc_driver.png)

**h**. Click "Choose File".

![](images/7_choose_file.png)

**i.** Select the JDBC driver you downloaded.

![](images/8_file_chosen.png)

**j.** Click "Upload".

![](images/9_choose_upload.png)

**k.** This concludes the JDBC driver upload. Here we see our new entry with the new JDBC driver we downloaded.

![](images/10_conclude_jdbc_upload.png)

## Step 4.

Create a new bucket to hold the JDBC driver. If you already have a designated bucket to hold the new JDBC driver, you can skip this step. For example, we will create a new bucket named "jars" to follow what is in the documentation. More information can be found at  [Create New Buckets in BucketFS Service](https://docs.exasol.com/administration/on-premise/bucketfs/create_new_bucket_in_bucketfs_service.htm). This step is an extension of [BucketFS Setup](https://docs.exasol.com/database_concepts/bucketfs/bucketfs_setup.htm).

a. Open the UI and navigate to the" EXABuckets" menu.

![](images/11_main_bucketfs_menu.png)

Assuming you are familiar with how to [Create a new bucket in the BucketFS service](https://docs.exasol.com/administration/on-premise/bucketfs/create_new_bucket_in_bucketfs_service.htm), we start with you having a "bucketfs1" or other bucket appearing in the "EXABucketFS Services" menu, such as:

![](images/12_bucketfs_service_menu.png)

**b.** Click on the "bucketfs1" link - which is under the "ID" column.

![](images/13_choose_bucketfs1.png)

**c.** Click Add to bring up a new bucket window:

![](images/14_add_bucket.png)

**d.** Set the new bucket named "jars".  Our example will set the READ and WRITE password to "abc". Checking the "Public readable" box enables any user to read from the bucket without a password. If you choose to enable "Public readable", then you really do not need to set the READ password. The WRITE password, on the other hand, must be filled in if you want this application to work properly.

![](images/15_create_jar_bucket.png)

**e.** Click "Add" to save the new "jars" bucket.

![](images/16_add_new_jar_bucket.png)

**f.** Make sure you see the new "jars" bucket. Take note of the "UDF path" column entry for the "jars" bucket, as we will be using it further down in this article.

![](images/17_verify_new_jars_bucket.png)

## Step 5.

Upload the new JDBC driver to the "jars" bucket. We will repeat this step later for uploading the virtual schema jar for SQL Server.

**a.** Open a command-line terminal. If you are running Windows, you can do it as follows: (WINDOWS Button) + r ==> cmd.exe. This should open the Command Prompt window for the command-line commands.  You should see something like this:

![](images/18_open_cmd_window.png)

**b.** Navigate to the Downloads directory or where ever you saved the new JDBC driver.

Navigate to the directory where you saved the SQL Server JDBC driver. To move to another directory, use the `cd`(change-directory) command, indicating the path to the directory holding the JDBC driver. In our example this is the "Downloads" directory, so we execute `cd Downloads`, as follows:

![](images/19_cd_downloads.png)

**c.**Make sure the JDBC driver is in the current directory. You can do it by using the `dir` command to see your directory contents, as follows:

![](images/20_validate_jdbc_in_dir.png)

**d.** Build your curl command in the terminal.

Referring to our previous bucket images, we see "bucketfs1" is using port 8080. 

![](images/30_get_bucketfs1_port.png)

Our curl command needs this port. Our example is using port 8080.

The "jars" directory is under the "bucketfs1" directory. Our curl command needs every directory under "bucketfs1" which leads to the final destination bucket containing the JDBC driver. Our example only has 1 directory under "bucketfs1" and that final destination is the "jars" bucket.

The `curl` command requires:

* The server hostname and port for accessing the bucket ("192.168.1.158:8080" in our case).
* The SQL Server JDBC driver JAR filename ("mssql-jdbc-9.2.0.jre8.jar" in our case)
* The write user and its password ("w:abc" in our case)
* The full path to the directory inside the bucket that will contain the JDBC driver ("/jars/" in our case)
* You can add the "-v" parameter to show the command execution output.

We build the command as follows:


```
curl -v -X PUT -T <JDBC_driver_filename> http://w:<write_password>@<server_host>:<bucket_port>/<path_to_directory_inside_bucket>/<JDBC_driver_filename>
```
In our case, it looks like:


```
curl -v -X PUT -T mssql-jdbc-9.2.0.jre8.jar http://w:abc@192.168.1.158:8080/jars/mssql-jdbc-9.2.0.jre8.jar
```
**e**. Run the curl command in the terminal window.

![](images/31_curl_command.png)

**f.** Make sure the uploading was successful. If the output of the command execution contains "HTTP/1.1. 200 OK", it means it was successful.

![](images/32_curl_verbose_output.png)

## Step 6.

Download the latest SQL Server Virtual Schema release from [sqlserver-virtual-schema/releases](https://github.com/exasol/sqlserver-virtual-schema/releases).

In our example, we are going to use the [SQL Server Virtual Schema 2.0.0](https://github.com/exasol/sqlserver-virtual-schema/releases/download/2.0.0/virtual-schema-dist-9.0.1-sqlserver-2.0.0.jar) release, as it is the most recent one to this date.

## Step 7.

Upload the SQL Server Virtual Schema jar file from the previous step to the "jars" directory.

For this, we are going to build and execute another `curl` command as in **Step 5,** but using the SQL Server Virtual Schema jar filename this time, as follows:


```markup
curl -v -X PUT -T virtual-schema-dist-9.0.1-sqlserver-2.0.0.jar http://w:abc@192.168.1.158:8080/jars/virtual-schema-dist-9.0.1-sqlserver-2.0.0.jar
```
Here is the output showing the upload was successful.

![](images/32_curl_verbose_virtual_schema.png)

This concludes the uploading section of this exercise.

## Step 8.

Install the Adapter script.

**a.** First you need to create the schema that will contain the Adapter script. Our example creates and uses the schema SCHEMA_FOR_VS_SCRIPT.


```markup
CREATE SCHEMA SCHEMA_FOR_VS_SCRIPT;
```
You can find more information about it at [sqlserver_user_guide](https://github.com/exasol/sqlserver-virtual-schema/blob/main/doc/user_guide/sqlserver_user_guide.md).

The `CREATE SCHEMA` command will also open the new schema. You can also explicitly open it with the `OPEN SCHEMA` command, as follows:


```markup
OPEN SCHEMA SCHEMA_FOR_VS_SCRIPT;
```
**b.** Create the Adapter Script by executing the "CREATE JAVA ADAPTER SCRIPT" command.

This command requires:

* The SQL Server Virtual Schema JAR filename ("virtual-schema-dist-9.0.1-sqlserver-2.0.0.jar" in our case)
* The SQL Server JDBC driver JAR filename ("mssql-jdbc-9.2.0.jre8.jar" in our case)
* The full path to the directory inside the bucket that contains the mentioned JAR files ("/buckets/bucketfs1/jars/" in our case)

We build the command as follows:


```
CREATE OR REPLACE JAVA ADAPTER SCRIPT SCHEMA_FOR_VS_SCRIPT.ADAPTER_SCRIPT_SQLSERVER AS 
 %scriptclass com.exasol.adapter.RequestDispatcher; 
 %jar /buckets/<BFS service>/<bucket>/<SQL_Server_Virtual_Schema_JAR_filename>; 
 %jar /buckets/<BFS service>/<bucket>/<SQL_Server_JDBC_driver_JAR_filename>; 
 /
```
In our case, it looks like:


```
CREATE OR REPLACE JAVA ADAPTER SCRIPT SCHEMA_FOR_VS_SCRIPT.ADAPTER_SCRIPT_SQLSERVER AS  
 %scriptclass com.exasol.adapter.RequestDispatcher;  
 %jar /buckets/bucketfs1/jars/virtual-schema-dist-9.0.1-sqlserver-2.0.0.jar;  
 %jar /buckets/bucketfs1/jars/mssql-jdbc-9.2.0.jre8.jar;  
/  

```
Referring back to our example images, we see the full path in the EXABucketFS Service Buckets under the "UDF path".

![](images/exa-John_0-1614169585207.png)
 
 ## Step 9.

**a.** Define the connection to the SQL Server database by executing the `CREATE OR REPLACE CONNECTION` command.

This command requires:

* The server hostname and port where the SQL Server database is running
* The user and its password to access to the SQL Server database

We build the command as follows:


```
CREATE OR REPLACE CONNECTION SQLSERVER_JDBC_CONNECTION  
TO 'jdbc:sqlserver://<server name>:<port>'  
USER '<user>'  
IDENTIFIED BY '<password>';
```
In our case, it looks like:


```
CREATE OR REPLACE CONNECTION SQLSERVER_JDBC_CONNECTION  
TO 'jdbc:sqlserver://192.168.1.158:1433'  
USER 'sa'  
IDENTIFIED BY 'xx$secret$xx';
```
The optional changes you can make are:

1. Change the connection name to something meaningful for your use case. The example connection name is "SQLSERVER_JDBC_CONNECTION".
2. Change the IP address from 192.168.1.158 to your SQL Server computer IP address or DNS name.
3. Change the credentials for "USER" and "IDENTIFIED BY". For example, the "USER" is "sa". You probably want to connect with a login appropriate for your use case. FYI this connection we are building is by definition, READ-ONLY to SQL Server. We can't run any DML like inserts or deletes using the SQL Server Virtual Schema.

**b.** Review work so far, as a lot has happened. The "LS" script is attached to this article.

**i.**  The BucketFS bucket "jars" contains both virtual schema jar and jdbc.jar.

![](images/exa-John_0-1614180981319.png)
 
 **ii.** The JDBC software section contains mssql-jdbc-9.2.0.jre8.jar. It is tied to the CONNECTION we created using the driver's prefix.

![](images/40_tie_connection_to_jdbc_driver.png)

## Step 10.

Create the Virtual Schema. We present the generic example first, followed by our example's use case.


```markup
CREATE VIRTUAL SCHEMA <virtual schema name>
    USING SCHEMA_FOR_VS_SCRIPT.ADAPTER_SCRIPT_SQLSERVER
    WITH
    CONNECTION_NAME = 'SQLSERVER_JDBC_CONNECTION'
    CATALOG_NAME   = '<database name>'
    SCHEMA_NAME = '<schema name>';
```
Here is our example's use case:


```markup
CREATE VIRTUAL SCHEMA SQLSERVER_DBO
    USING SCHEMA_FOR_VS_SCRIPT.ADAPTER_SCRIPT_SQLSERVER
    WITH
    CONNECTION_NAME = 'SQLSERVER_JDBC_CONNECTION'
    CATALOG_NAME   = 'john'
    SCHEMA_NAME = 'dbo';
```
The optional changes you can make for your use case:

1. Change the Virtual Schema name from SQLSERVER_DBO to something appropriate for your use case (or not).
2. Change the CONNECTION_NAME for SQLSERVER_JDBC_CONNECTION to the name of the connection created in Step 9.
3. Change the CATALOG_NAME to your SQL Server database name (not the instance name). Our example has the CATALOG_NAME set to "john".
4. Change the SCHEMA_NAME to your SQL Server's database schema. Our example has SCHEMA_NAME set to "dbo".

## Step 11.

Before testing our SQL Server Virtual Schema, let's look under the hood to see what we built.

**a.** Run this query to see the basic Virtual Schema information inside Exasol. You should see your new SQL Server schema name under the column SCHEMA_NAME and the new Adapter script under ADAPTER_SCRIPT. 


```markup
select * from exa_dba_virtual_schemas;
```
**b.**  Show the Virtual Schema properties. Our example should show the SCHEMA_NAME as "SQLSERVER_DBO", followed by the PROPERTY_NAME and PROPERTY_VALUE.


```markup
select * from exa_dba_virtual_schema_properties;
```
**c.** Take your pick of what you want to look at. This query will pull up all the tables and views devoted to Virtual Schemas.


```markup
select * from exa_syscat where object_name like '%VIRTUAL%';
```
## Step 12.

Before you leave, you should assign permissions to the connection and virtual schema to your Exasol users. We will provide an example after mentioning additional information can be found here at 

* [Virtual Schema Privileges](https://docs.exasol.com/database_concepts/virtual_schema/virtual_schema_privilege.htm)
* [Virtual Schemas](https://docs.exasol.com/6.1/database_concepts/virtual_schemas.htm)
* [Details on Rights Management](https://docs.exasol.com/database_concepts/privileges/details_rights_management.htm)  -- see the paragraph for "SCHEMAS".

One of the hidden facts about granting permissions is if a view contains a table from a virtual schema, access rights are necessary on the corresponding adapter script.


```markup
OPEN SCHEMA RETAIL;
DROP USER IF EXISTS USER1 CASCADE;
CREATE USER USER1 IDENTIFIED BY "abc";
--=========================================--
-- GRANT SYSTEM PRIVILEGES                 --
--=========================================--
GRANT CREATE SESSION TO USER1;
GRANT IMPORT TO USER1;(optional - only need if query is running an IMPORT FROM JDBC)
--=========================================--
-- GRANT OBJECT PRIVILEGES                 --
--=========================================--
GRANT CONNECTION SQLSERVER_JDBC_CONNECTION TO USER1;
GRANT EXECUTE ON SCRIPT SCHEMA_FOR_VS_SCRIPT.ADAPTER_SCRIPT_SQLSERVER TO USER1;
GRANT ACCESS ON CONNECTION SQLSERVER_JDBC_CONNECTION FOR SCRIPT SCHEMA_FOR_VS_SCRIPT.ADAPTER_SCRIPT_SQLSERVER to USER1;
--=========================================--
-- Prep to run as USER1
--=========================================--
OPEN SCHEMA SQLSERVER_DBO;
IMPERSONATE USER1;
```
## Step 13.

 The final test is to query SQL Server. Our example will run a native SQL Server query against a test database named, "john", with schema "dbo" and table "t".


```markup
SELECT * FROM "t" ORDER BY "col1" DESC;
```
![](images/final_results.png)

## Additional References

* [Virtual Schema Privileges](https://docs.exasol.com/database_concepts/virtual_schema/virtual_schema_privilege.htm)
* [Details of Rights Management](https://docs.exasol.com/database_concepts/privileges/details_rights_management.htm)
* [Microsoft SQL Server Dialect User Guide](https://github.com/exasol/sqlserver-virtual-schema/blob/main/doc/user_guide/sqlserver_user_guide.md)
* [SQL Server Virtual Schema Releases](https://github.com/exasol/sqlserver-virtual-schema/releases/)
* [Supported Data Sources](https://docs.exasol.com/database_concepts/virtual_schema/supported_data_sources.htm)
