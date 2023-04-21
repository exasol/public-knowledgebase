# How to create ODBC Logfiles with Tableau 
## Background

You want to create an ODBC logfile from Tableau.

## Prerequisites

* Create a copy of your Tableau workbook
* Open your Tableau workbook copy with a text-editor (the format is XML)

## How to create ODBC Logfiles with Tableau

## Step 1

Find your datasource and edit the connection class:


```"code-xml"


<workbook>
  <datasources>
    <datasource caption='your_datasource_name' ...>
      <connection class='exasolution' odbc-connect-string-extras='' port='8563' schema='YOURSCHEMA' server='192.168.10.11..22:8563'...>
```
## Step 2

Now modify the **odbc-connect-string-extras**


```"code-xml"
      <connection class='exasolution' odbc-connect-string-extras='EXALOGFILE=D:\logfiles\TableauODBC.log;LOGMODE=DebugComm' port='8563' schema='YOURSCHEMA' server='192.168.10.11..22:8563' ...> 
```
## Step 3

Now open this workbook again with Tableau and do everything you want to have within the ODBC logfile.

## Additional References

For all ODBC logfile options, please refer to the user manual.

<https://docs.exasol.com/connect_exasol/drivers/odbc.htm>

<https://docs.exasol.com/connect_exasol/bi_tools/tableau.htm>

<https://exasol.my.site.com/s/article/How-to-use-Exasol-as-a-Linked-Server-in-SQL-Server>

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 