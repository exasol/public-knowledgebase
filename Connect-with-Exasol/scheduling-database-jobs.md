# Scheduling Database Jobs 
## Question

I want to run a query or job regularly, without having to do this manually. How can I schedule these to run automatically? 

## Answer

Exasol does not offer an in-database scheduler. There is a variety of 3rd party tools that you can use to schedule jobs to run in the database, as long as the software is able to connect directly to Exasol or can run an external command like Exaplus. 

One method is to install Exaplus CLI on a Linux environment, and set up a Cron Job which opens up Exaplus. You can find more information about Cron Jobs [here](https://ostechnix.com/a-beginners-guide-to-cron-jobs/). The cronjob will run every x minutes or hours, and will connect to the database via Exaplus. Within the Exaplus command, you can specify either a query to run, or a file containing multiple SQL Files. 

You can specify your credentials directly in the command, but we recommend to use an [Exaplus Profile](https://docs.exasol.com/connect_exasol/sql_clients/exaplus_cli/exaplus_cli.htm) so that you only enter this information once and it is not visible to other users:


```markup
/usr/local/bin/exaplus -u sys -p exasol -c <ip_address>:8563 -wp my_db_profile
```
For example, the command below will insert the current_timestamp every minute into a table:


```markup
*/1 * * * * /usr/local/bin/exaplus -profile my_db_profile -sql "INSERT INTO TEST.TIMES SELECT CURRENT_TIMESTAMP;" 
```
If I have multiple commands, you can either create a Lua Script that contains all of your statements, or you can create a new file containing all of the commands. For example, I can create a file (my_sql.sql) that contains these commands:


```markup
SELECT CURRENT_SESSION; SELECT CURRENT_TIMESTAMP; INSERT INTO TEST.TIMES SELECT CURRENT_TIMESTAMP;
```
Now I can set up the cron job to use this file instead of a single command:


```markup
*/1 * * * * /usr/local/bin/exaplus -profile my_db_profile -f /home/my_sql.sql 
```
## Additional References

* [Beginner's Guide to Cron](https://ostechnix.com/a-beginners-guide-to-cron-jobs/)
* [Exaplus CLI](https://docs.exasol.com/connect_exasol/sql_clients/exaplus_cli/exaplus_cli.htm)
