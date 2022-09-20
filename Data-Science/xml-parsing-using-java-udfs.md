# XML-parsing using Java UDFs 
## Background

This solution describes how to use the Java DOM Parser to parse an XML-Text stored in an EXASOL database. The solution will result in a Java-UDF that can be used to structure the content of a XML-Text. Documentation on the DOM Parser can be found here:  
<http://www.tutorialspoint.com/java_xml/java_dom_parse_document.htm>

The general approach is:

1. Implementation and tests (pure Java, Maven)
2. Deployment (EXABucketFS)
3. UDF implementation (EXASOL-SQL, Java)
4. Usage (EXASOL-SQL)

### Important notes

The solution uses a maven-assemble-plugin to create a single jar including all dependencies. Otherwise, it would be necessary to deploy all dependencies (including DOM Parser, ...) manually to the EXASOL cluster.

## Prerequisites

This solution was created by using the following tools and features:

1. EXASOL database > V6, advanced edition
2. JDK
3. Eclipse (Mars)
4. Maven, including the maven-assembly-plugin (<http://maven.apache.org/plugins/maven-assembly-plugin/>)

## Using Java UDF for XML-parsing

## Step 1. Java implementation and tests

### Implementation

Within the attached xmlexample.zip file you will find 8 files:

1. City.java (Represents a "row" in a CITIES table. Members: ID and Name)
2. DomParserExample.java (XML-parsing implemenation)
3. DomParserExampleTest.java (XML-parsing test)
4. ProcessXML.java (run method, according to EXASOL java UDF run method)
5. Data.java(Emulates a table)
6. Iterator.java (Used for JUnit tests for ProcessXML, implements ExaIterator)
7. Metadata.java (Used for JUnit tests for ProcessXML, implements ExaMetadata)
8. ProcessXMLTest.java (JUnit test for the run method)

In addition, the pom.xml for maven is attached as part of xmlexample.zip 

. The POM file includes JUnit, and maven-assembly-plugin (used to create a single jar including all dependencies).

### Maven project in Eclipse:

## Step 2. Building the sources

1. "cd" to the workspace of the maven project
2. run "mvn clean package assembly:single"  
The jar with all dependencies can be found in the "target"-folder. Name: "xmlexample-0.0.1-SNAPSHOT-jar-with-dependencies.jar"

You can find a precompiled jar attached to this solution. xmlexample-0.0.1-SNAPSHOT-jar-with-dependencies.jar 

## Step 3. Deploying jar to EXASOL cluster

Look in our documentation that describes how to install jar libraries in the cluster.  
For this solution, the fat jar was deployed to an EXABucket named "jars" using the following curl© command:


```"code
curl -X PUT -T xmlexample-0.0.1-SNAPSHOT-jar-with-dependencies.jar   http://w:<w_pwd>@<db_node>:<EXABucketFS_port>/jars/xmlexample-0.0.1-SNAPSHOT-jar-with-dependencies.jar 
```
## Step 4. UDF and usage

The attached file Data.sql creates a table for storing the XML-Text and inserts two rows (including two rows for the CITIES table, each).   
**Please note**: This approach requires the XML texts to have less than 2 million characters.


```"code
Data.sqlcreate schema xmlparsing;  create or replace table myXML (v varchar(2000000));  insert into myXML values  '<?xml version="1.0" encoding="UTF-8" standalone="yes"?> <document>           <entry>           <id>1</id>           <name>Nuremberg</name>      </entry>      <entry>           <id>2</id>           <name>Berlin</name>      </entry> </document>';  insert into myXML values  '<?xml version="1.0" encoding="UTF-8" standalone="yes"?> <document>           <entry>           <id>3</id>           <name>London</name>      </entry>      <entry>           <id>4</id>           <name>Stockholm</name>      </entry> </document>';  commit; 
```
The attached file UDF.sql   describes how to create a UDF that imports the installed jar library and uses the XML-parsing functionality.  
In addition, the UDF function is used to insert data into an EXASOL table.


```"code
UDF.sqlcreate or replace java scalar script processXML(xml varchar(2000000))  emits (id int, name varchar(200000)) as %scriptclass com.exasol.xmlexample6.ProcessXML;  %jar /buckets/bucketfs1/jars/xmlexample-0.0.1-SNAPSHOT-jar-with-dependencies.jar; } / commit; -- Usage: SELECT select processXML(v) from xmlparsing.myxml;  -- Usage: INSERT INTO ... FROM SELECT create table cities (id int, name varchar(200000)); insert into cities select processXML(v) from xmlparsing.myxml; commit;  select * from cities;  
```
## Step 5. Use UDF for ETL

The last example shows how to use the functionality for inserting data into a table via a SELECT statement.  
For ETL matters you typically want to change two different things:

1. Use the IMPORT statement instead of INSERT ... SELECT
2. Load XML file from a server

For 1. we will demonstrate how to use the existing UDF for an ETL UDF. 2. It will not be demonstrated to keep this solution as simple as possible, but the existing code could easily be extended to connect to a server (e.g. FTP) to retrieve the XML file.

### IMPORT FROM UDF

The delivered source code already includes the method "generateSqlForImportSpec(...)" which is mandatory for ETL UDFs.  
Class ProcessXML.java:


```"code
// ... public static String generateSqlForImportSpec(ExaMetadata meta, ExaImportSpecification importSpec)  {           Map<String, String> params = importSpec.getParameters();                      String etludf = new String(meta.getScriptSchema() + "." + meta.getScriptName());                      String mySelect = new String("SELECT ");             mySelect += etludf;           mySelect += " (";           mySelect += params.get("COLUMN_NAME");           mySelect += ") FROM ";           mySelect += params.get("TABLE_NAME");           return mySelect; } // ... 
```
## Additional Notes

This callback function is called by the EXASOL engine if you use the UDF within an IMPORT statement and generates an appropriate SELECT statement for the IMPORT.

This solution requires that the table storing the XML data is located in the currently opened schema, but could be extended with a property "SCHEMA_NAME" easily.

## Additional References

<https://community.exasol.com/t5/database-features/examining-expression-types-using-udf/ta-p/1436>

<https://community.exasol.com/t5/data-science/custom-aggregate-functions-for-large-data-sets/ta-p/1420>

<https://community.exasol.com/t5/data-science/using-custom-jar-java-archive-libraries-within-udfs/ta-p/1113>

<https://community.exasol.com/t5/data-science/how-to-create-and-use-udfs/ta-p/501>

