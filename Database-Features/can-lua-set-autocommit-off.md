# Can LUA Set AutoCommit Off?

## Question
I'm facing troubles when turning AUTOCOMMIT OFF - my Lua script is called via JDBC, they have said that they've turned off AUTOCOMMIT, but still I can see "GlobalTransactionRollback msg: Transaction collision: automatic transaction rollback."

Now my idea was to turn off AUTOCOMMIT in Lua - but how? Does anybody know if this is possible and if so, please let me know how.

> query([[SET AUTOCOMMIT OFF]]);

The code above does not work.

## Answer
AUTOCOMMIT settings are done at the client layer - either by the JDBC connection or by your SQL client.

A Lua script is executed at the database layer, therefore it cannot control this setting.

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 