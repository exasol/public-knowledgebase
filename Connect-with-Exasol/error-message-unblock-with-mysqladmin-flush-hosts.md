# Error message Unblock with 'mysqladmin flush-hosts' 
In this article, we explain to you the reason behind the error message unblock with 'mysqladmin flush-hosts' and how to deal with it.

## Scope

When connecting to external network services from a database (e.g. via IMPORT/EXPORT commands or scripts), a user may get an error message to unblock with 'mysqladmin flush-hosts'.

## Diagnosis


```
select * from  
 (import from JDBC DRIVER='MySQL8' at MYSQL_TEST statement 'select * FROM dual');
```
Fails with:


```
SQL Error[ETL-5]: JDBC-Client-Error: Connecting to 'jdbc:mysql://u....com:3306' as user='user' failed: 
null, message from server: "Host 'xxx' is blocked because of many connection errors; 
unblock with 'mysqladmin flush-hosts'" 
```
## Explanation

Exasol has to communicate with the MySQL server. If Exasol receives an error message from the MySQL server Exasol prints this message. This message is caused by the MySQL server.   
In the example above it means the number of faulty connections is exceeded. 

## Recommendation

You have to perform an unlock.

There are 2 possibilities:

1. Run the following SQL statement in your **MySQL SQL client** (such as phpMyAdmin)::  
 
```
FLUSH HOSTS;
```
2. If you have shell access to the server, you can log in and do:  
 
```
mysql -u root -p -e 'flush hosts'
```

You can find out what causes these faulty connections in the MySQL error log file in the data directory. Now you can try to execute the command again. 

## Additional References

* <https://dev.mysql.com/doc/refman/8.0/en/flush.html>
* <https://try2explore.com/questions/12547909>
* <https://www.xperttimer.de/faq/ich-erhalte-den-fehler-host-is-blocked-because-of-many-connection-errors-unblock-with-mysqladmin-flush-hosts> (written in German)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 