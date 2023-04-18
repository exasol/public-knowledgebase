# CSV format for IMPORT/EXPORT: General formatting rules 
## General formatting rules

To ensure a proper import of your data there are some rules that have to be considered when creating the csv file. 

* NULL (data field with no content) has to be converted to "" (empty string)
* Double quotes in a text field have to be masked with double quotes ("Example" -> ""Example"")  
-> Masking with backslash (or the like) is NOT supported!
* Data type TIMESTAMP: Date and time information have to be separated by SPACE  
e.g.   
"YYYY-MM-DD HH:MM:SS"     
"YYYY-MM-DD-HH:MM:SS"
* Data type DATE: "0000-00-00" is NOT supported and has to be converted to "" (empty string)
* UCS2 and UTF-16 are not supported => use UTF-8 or similar.

See a detailed desciption in the Exasol User Manual.

