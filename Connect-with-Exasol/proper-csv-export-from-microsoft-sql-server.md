# Proper csv export from Microsoft SQL Server 
How do I export CSV files properly from Microsoft SQL Server? Choose one option and follow the instructions.

## Option 1: Using the SQL Server Import and Export Data Wizard / DTSWizard

Note: This tool should be included in your SQL Server installation

* Open the wizard 
* Select your data source and the database you want to export
* Continue with ***Next***
* Select ***Flat File Destination*** as your destination and browse to the desired file path for your csv file. It is necessary to use *.csv as your file extension  
***Note: If you want to override an existing file, you have to delete the old file first! Otherwise, the exported data will be appended to the existing file.***
* Change the ***Text qualifier*** to ***“*** (double quotes) and set ***UTF-8*** as ***Code page***
* Continue by clicking ***Next***
* Since double quotes will not be escaped properly, you have to select ‘***Write a query to specify the data to transfer***’ and proceed with clicking ***Next***
* Now fill in a valid ***SELECT Statement*** to select the data you want to export  
***Note: It is important to make use of the REPLACE function to ensure proper masking of double-quotes. It is only necessary for Columns that might contain strings with double-quotes.***  
(Documentation of ***REPLACE***:<https://msdn.microsoft.com/de-de/library/ms186862.aspx>)  
Example:  

```markup
SELECT  [Customer Key],  [WWI Customer ID],  
 REPLACE([Customer], '"', '""') AS 'Customer',  
 REPLACE([Bill to Customer], '"', '""') AS 'Bill to Customer',  
 REPLACE([Category], '"', '""') AS 'Category',  
 REPLACE([Buying Group], '"', '""') AS 'Buying Group',  
 REPLACE([Primary Contact], '"', '""') AS 'Primary Contact',  
 [Postal Code],  [Valid From],  [Valid To],  [Lineage Key]  FROM Dimension.Customer​
```
* Confirm your settings for the ***Flat File Destination*** and continue with ***Next***
* Start the export by clicking ***Finish***
* You will receive a short report about the successful export

## Option 2: Using the ***bcp Utility***

As this method is kind of unhandy, we recommend using option 1. If, for some reason, you are not able to use the ***DTS Wizard*** you can use the following manual to export your data with the ***bcp Utility***. (Documentation ***bcp Utility***: <https://msdn.microsoft.com/en-us/library/ms162802.aspx>)

* The needed ***bcp*** command looks something like this:  
bcp “SELECT STATEMENT” queryout “OUTPUT FILEPATH” –c –t”,” –r”\n” –q –S SERVERNAME –T
* To ensure a correct export, the ***SELECT Statement*** has to meet certain criteria:
* All columns that might contain ***commas***, ***double quotes,*** or any other special characters, have to be enclosed by “***char(34)***” (ASCII Code for ***"***). This will add ***double quotes*** before and after the exported field.  
Example:  
“SELECT  
[Customer Key],  
***char(34)*** + [Customer] + ***char(34)***  
FROM …”
* All columns that might contain ***double quotes***, have to be selected with the ***REPLACE*** function. This way, ***double quotes*** will be masked properly in your csv file ("Example" -> ""Example"").  
Example:  
“SELECT  
[Customer Key],  
***char(34)*** + [Customer] + ***char(34)***,  
***char(34)*** + ***REPLACE([Category], char(34), char(34) + char(34))*** + ***char(34)***  
FROM …”  
***Note: Since the SELECT Statement has to start with double quotes, you have to use char(34) as a replacement for " as well. Otherwise, the console would interpret it as the end of the SELECT Statement.***  
***REPLACE([Category], ", "")*** -> ***REPLACE([Category], char(34), char(34) + char(34))***  
(Documentation of ***REPLACE***: <https://msdn.microsoft.com/de-de/library/ms186862.aspx>)
* All columns that allow entries being ***NULL***, must use the ***COALESCE*** function. This guarantees proper conversion from ***NULL*** to “” (empty string).  
Example:  
“SELECT  
[Customer Key],  
***char(34)*** + [Customer] + ***char(34)***,  
***char(34)*** + ***REPLACE([Category], char(34), char(34) + char(34))*** + ***char(34)***,  
***char(34)*** + COALESCE([Primary Contact],'') + ***char(34)***  
FROM…”  
***Note: ******COALESCE****** is using two single quotes as a second parameter!***  
***You might have to combine the functions depending on your database design.***  
Example:  
“SELECT  
[Customer Key],  
***char(34)*** + [Customer] + ***char(34)***,  
***char(34)*** + COALESCE(***REPLACE([Category], char(34), char(34) + char(34))***, '') + ***char(34)***,  
***char(34)*** + COALESCE([Primary Contact],'') + ***char(34)***  
FROM…”
* A complete bcp command can look as follows:  
bcp "Select  
[Customer Key],  
[WWI Customer ID],  
***char(34)*** + [Customer] + ***char(34)***,  
***char(34)*** + [Bill to Customer] + ***char(34)***,  
***char(34)*** + ***REPLACE([Category], char(34), char(34) + char(34))*** + ***char(34)***,  
***char(34)*** + [Buying Group] + ***char(34)***,  
***char(34)*** + COALESCE(***REPLACE([Primary Contact],char(34),char(34) + char(34))***,'') + ***char(34)***,  
***char(34)*** + [Postal Code] + ***char(34)***,  
[Valid From],  
[Valid To],  
[Lineage Key]  
From WideWorldImporters.Dimension.Customer"  
queryout "C:\Test.csv" -c -t"," -r"\n" -q -S HW1729 –T
* Start the export by pressing Enter



