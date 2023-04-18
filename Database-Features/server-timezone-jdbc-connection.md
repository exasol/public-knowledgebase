# Server Timezone JDBC Connection

## Question
I'm using a LUA function to pull data from a mysql database.  

MySQL database operates in UTC and Exasol Server is on America/New York . The function uses the mysql function from_unixtime() to convert from utc unixtime to utc datetime format but it looks like when I pull from the UDF, the datetime is already converted to the server timezone when I really I need to be storing UTC timestamps. 

Is there a way that I can set outside my function or without hardcoding the timezone conversion (as it is a function that is used in multiple environments) to make sure that the timezone is honored?

## Answer
Do you use a new JDBC-Connection To MySQL in the UDF? You could then overwrite the server-timezone with the JDBC-param to your own timezone, thereby preventing the conversion:

&serverTimezone=&lt;YOURTIMEZONE&gt;
Then all you would need to do is, to query the local timezone in same function and use it in there, so the function works in any timezone then.