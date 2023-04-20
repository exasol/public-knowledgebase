# Connecting Spotfire Server with EXASOL via JDBC 
## Background

This article describes a way how to connect Spotfire to Exasol.

## Prerequisites

Download the EXASOL JDBC driver and extract the exajdbc.jar 

## How to connect Spotfire to Exasol

## *Step 1*

Copy the exajdbc.jar to to the Spotfire library directory, see the following link where this directory is located: <https://community.tibco.com/wiki/tibco-spotfirer-jdbc-data-access-connectivity-details#toc-2>

## *Step 2*

Restart the Spotfire Server so the EXASOL jdbc driver is loaded.

## *Step 3*

Start the Spotfire Server configuration tool

## *Step 4*

Go to the Configuration tab and create a new Data Source Template

## *Step 5*

In the Add data source template enter EXASOL as name and copy paste the following template:


```"code-java"
<jdbc-type-settings>
<type-name>EXASOL</type-name>
<driver>com.exasol.jdbc.EXADriver</driver>
<connection-url-pattern>jdbc:exa:&lt;host&gt;:&lt;port&gt;;clientname=Spotfire;</connection-url-pattern>
<ping-command>SELECT 1</ping-command>
<supports-catalogs>false</supports-catalogs>
<supports-schemas>true</supports-schemas>
<java-to-sql-type-conversions>
 <type-mapping>
 <from max-length="2000000">String</from>
 <to>VARCHAR($$value$$)</to>
 </type-mapping>
 <type-mapping>
 <from>Integer</from>
 <to>DECIMAL(18,0)</to>
 </type-mapping>
 <type-mapping>
 <from>Long</from>
 <to>DECIMAL(36,0)</to>
 </type-mapping>
 <type-mapping>
 <from>Float</from>
 <to>REAL</to>
 </type-mapping>
 <type-mapping>
 <from>Double</from>
 <to>DOUBLE PRECISION</to>
 </type-mapping>
 <type-mapping>
 <from>Date</from>
 <to>DATE</to>
 </type-mapping>
 <type-mapping>
 <from>DateTime</from>
 <to>TIMESTAMP</to>
 </type-mapping>
</java-to-sql-type-conversions>
</jdbc-type-settings>
```
## *Step 6*

Save the config, close the configuration tool and restart the server

## *Step 7*

Check the logs if the XML config for EXASOL was validated correctly

## *Step 8*

Use the Information Designer tool in the Spotfire Analyst to create a new Data Source

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 