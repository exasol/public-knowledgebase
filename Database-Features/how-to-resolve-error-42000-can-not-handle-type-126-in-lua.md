# How to resolve  error 42000:Can not handle type: 126 in LUA Scripts 
You might face the exception `**Can not handle type: 126**` in LUA scripts. This article will show you how to resolve this issue.

## Diagnosis

While reading from a Hashtype value of a result rom a query in a LUA script, you might see the following error message:


```sql
[Code: 0, SQL State: 42000] Can not handle type: 126 (Session: 1714879254894739456)
```
## Explanation

Exasol doesn't support Hash-Types in Lua-Scripts. See <https://docs.exasol.com/7.1/database_concepts/udf_scripts/lua.htm#Parameters>

Example:


```sql
--/ CREATE OR REPLACE lua script test.test_hashtype() returns rowcount AS  SQL = "select A from  (VALUES (hashtype_md5('A')) AS t(a))" res = query(SQL) SQL = "select '"..res[1].A.."'" /  EXECUTE script test.test_hashtype();
```
## Recommendation

Casts must be done for Return Values from (p)query queries which are based upon Hashtypes. That is we cast "A" as varchar(32) to hold the "(VALUES (hashtype_md5('A')) AS t(a))". Here is a simple Lua script displaying (via the "output" command) the results.


```sql
--/ CREATE OR REPLACE lua script test.test_hashtype() returns rowcount AS  SQL = "select cast (A as varchar(32)) as A from  (VALUES (hashtype_md5('A')) AS t(a))" suc, res = pquery(SQL) for i=1, #res do     output("res[1][i]"..res[1][i]) end /  EXECUTE script test.test_hashtype() with output;
```
er 

## Additional References

* <https://docs.exasol.com/7.1/database_concepts/udf_scripts/lua.htm#Parameters>
