# How to Connect to Exasol Using PHP

## Question
I'm a developer and my company is testing Exasol. 

I have been asked to connect a PHP program to an Exasol database which is not on the same host as the php program.

I have tried a lot syntax either using PHP PDO built in class or PHP odbc_connect() built-in function but nothing worked.

Do you guys have once conncted a php program to Exasol ? How did you do that ?

## Answer
Accessing Exasol from PHP is more or less straight forward:
```
\<?php  

$connection = odbc_connect('my_dsn','sys','exasol');

$result = odbc_exec( $connection, "select param_value || ' accessed from PHP' from exa_metadata where param_name='databaseName'" );  

while(odbc_fetch_row($result)){  
       for($i=1;$i<=odbc_num_fields($result);$i++){  
        echo "Result is ".odbc_result($result,$i);  
    }  
}  
?>
```
The "my_dsn" is an ODBC registration on my host, the exasol system is running on a VirtualBox ( so not strictly "not on the same host", but since the DSN on your PHP server would cover the connection string locality shouldn´t be an issue).