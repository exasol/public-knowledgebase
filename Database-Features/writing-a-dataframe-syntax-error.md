# Writing a DataFrame Syntax Error 

## Question
Hi all, I am facing this issue attempting to write a DataFrame to a table using Exasol JDBC. 

Upon running this statement,
```
test_table.write.format('jdbc').options(  
    url='jdbc:exa:'+exasol_adress,   
    driver='com.exasol.jdbc.EXADriver',   
    dbtable='TEST.CSV_TABLE',   
    user='sys',   
    password='exasol',   
    create_table='true').mode('append').save()  
```

the following error is thrown:
```
java.sql.SQLSyntaxErrorException: syntax error, unexpected IDENTIFIER_LIST_, expecting ',' or ')'
```
 

It seems to me, as if this was translated into SQL incorrectly by a driver resulting in a syntax error.

As for the setup that might be relevant, I am using Exasol JDBC driver 7.0.4, with Spark 3.0.1.

## Answer
Create the table in advance (using varchars) and then set create_table='false'.

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 