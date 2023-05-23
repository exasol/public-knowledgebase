# Parallel script execution inside a Lua script 
## Background

The only working solution is using the IMPORT command over JDBC to connect to your Exasol database and wrap the LUA-scripts you want to execute in parallel in the STATEMENT-Clause.

## Prerequisites

You are using an enterprise version of Exasol, not the single node community edition. 

## How to run Import in parallel using JDBC and LUA

The following small example shows this approach:


```"code
create or replace lua script cat_return returns table as
--Lua script that returns resultset of select * from cat
--used to test parallel call

suc, res = pquery([[select * from cat]],{})

tab = {}

for i=1, #res do

	tmp2 = {}
	for j=1, #res[i] do
		table.insert(tmp2, res[i][j]) 
	end

	table.insert(tab, tmp2)

end

return tab, 'TABLE_NAME VARCHAR(200), TABLE_TYPE VARCHAR(200)'

/

create or replace lua script partest returns rowcount as
--Parallel execution of other lua scripts
--performed using import statement

suc, res = pquery([[

	IMPORT INTO (TABLE_NAME VARCHAR(200), TABLE_TYPE VARCHAR(200)) FROM JDBC 
	AT 'jdbc:exa:192.148.120.16..20:8563;schema=MYUSER'
	USER 'myuser' IDENTIFIED BY 'xxxxxxxxx'
	STATEMENT 'execute script myuser.cat_return'
	STATEMENT 'execute script myuser.cat_return'
	STATEMENT 'execute script myuser.cat_return';

]],{})

return {rows_affected = #res}

/

execute script partest;
```
## Additional References

[Using UDf's to implement generic analytic functions with support for complex windowing](https://exasol.my.site.com/s/article/Using-UDf-s-to-implement-generic-analytic-functions-with-support-for-complex-windowing)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 