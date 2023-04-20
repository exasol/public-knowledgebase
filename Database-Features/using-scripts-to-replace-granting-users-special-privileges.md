# Using scripts to replace granting users special privileges 
## Scope

Database Best Practices almost always emphasize the least privileged access principle, and we abide by it. Exasol takes security and permissions very seriously and assigning which users receive elevated privileges can, at times, be confusing. For example, in Exasol, scripts and UDFs are executed using the privileges of the invoker running the script, not the script owner. Does the invoker have the needed privileges to execute the queries inside the script? 

### Terminology

Before we continue, just within this article, the terms "scripts" and "UDFs" will be used interchangeably, to signify the canned-up SQL (a database object) you have inside the database. The only significant difference between the "script" and a "UDF" is an invocation. Lua scripts are executed with the EXECUTE SCRIPT ... command. UDFs are invoked with a SELECT... command. As you read through the solution, this concept will become clearer, by demonstration.

To add clarification, only Lua scripts are invoked with EXECUTE SCRIPT... All other Python, R, Java, etc., scripts are known as User Defined Functions, or UDFs and are invoked with a SELECT... command.

## Diagnosis

Your use case needs to create users, roles, etc., but assigning elevated database privileges to users to do these tasks can open vulnerabilities. If you grant the privilege GRANT ANY PRIVILEGE to a user, then the user can turn around and GRANT ANY ROLE to themselves, which means they can grant themselves the DBA role. Not good! Scripts on the other hand, only do what they are created to do. We are presenting a way to give scripts and UDFs elevated privileges and only allowing users to execute the script / UDF.

## Explanation

In further explicating this concern, we can use a hypothetical company that has many users and a constantly changing database. The idea of granting a user special privileges to carry out repetitive tasks within the database can lead to mistakes, unintentional changes, or worst-case scenario, questionable practices. Just granting this user special permissions while the script is being executed is not feasible, as there are many daily database changes, and auditing this grant/revoke cycle would be a nightmare. We need the appropriate privileges to be granted only once, allowing database users to continue doing work, without being impeded by insufficient privileges.

## Recommendation

We are going to demonstrate a way to use scripts to manage database objects, with the privileges being distributed between the database connection, the script that uses the connection, and the end-user who invokes the script. 

### Prologue

Before we begin, included in this article is the SQL command: "GRANT IMPERSONATION ON SYS TO JOHN".  This will allow you to run the entire solution in the same session that is being run as the SYS user. Two suggestions, which I advise you understand before moving on.

**1**) "GRANT IMPERSONATION ON SYS TO JOHN" allows the user JOHN to become the SYS user, which means having the DBA role. Do not use this in production, but rather open a second session and set it to be running as the user JOHN, using this SQL.


```sql
IMPERSONATE JOHN;
```
**2**) When concluding your development testing, be sure and execute either "DROP USER JOHN CASCADE " or "REVOKE IMPERSONATION ON SYS FROM JOHN". Otherwise, you have a gaping security issue in your development region. 

## Begin Solution

#### Solution Summary:

1) Create and test Connection

2) Create Schema

3) Create and test a new test user

4) Create and test Lua script

5) Create and test Python wrapper/proxy script

6) Test new solution as SYS user

6) Assign permissions for the test user and test solution, including regression testing

### Create Connection

Let start with a connection. This might seem insecure as the SYS user credentials are exposed, but later in this article, we see credentials masking or credentials hiding. See the *Additional References* section at the bottom of this article for more information.


```sql
--===================================-- 
-- Set up Connection 
--===================================-- 
CREATE OR REPLACE CONNECTION SYS_CONN to 'localhost:8563' user 'sys' identified by 'exasol';
```
Where:

**localhost** *-- The Exasol Host Name or the I.P. Address*

**8563** *-- Is the Database port, which may need to be updated to reflect your company's Exasol connection port*

**sys** *-- Is the DBA user, which does not have to be SYS, you can create other users and give them DBA privileges*

**exasol** *-- Is the DBA user's password to access Exasol*

### Test the connection

You can test the connection, by running this query as the SYS user:


```sql
select * from (IMPORT FROM EXA AT SYS_CONN statement 'select current_date');
```
Notice the SQL part IMPORT FROM EXA. This means we are using the built-in Exasol driver to connect. You can find examples here [import](https://docs.exasol.com/7.0/sql/import.htm). The results of the above query should return a column named CURRENT_DATE with the current data as the value. For more information on connections, see [create_connection](https://docs.exasol.com/sql/create_connection.htm), [alter_connection](https://docs.exasol.com/sql/alter_connection.htm). You can see existing connections in the EXA_DBA_CONNECTIONS table, see [exa_dba_connections](https://docs.exasol.com/7.0/sql_references/system_tables/metadata/exa_dba_connections.htm). As loading data requires a connection, you can find more connection examples here [loading_data/load_data_from_externalsources](https://docs.exasol.com/7.0/loading_data/load_data_from_externalsources.htm).

### Create Schema

 We are going to create a test schema to hold our scripts. If you already have a schema named "RETAIL", simply adjust to define and use whatever schema name you desire.


```sql
CREATE SCHEMA IF NOT EXISTS RETAIL; 
OPEN SCHEMA RETAIL;
```
 ### **Optional** Simple Example of Solution

 This optional part is only to demonstrate using a simple Python scalar script that incorporates the hidden credentials we mentioned above. This Python script is not a wrapper, nor part of the workaround. It simply introduces the concept of using a script to access credentials and run a query.

 
```sql
--===================================--
-- Create the optional Python demonstration script
--===================================--
--/
CREATE OR REPLACE PYTHON3 SCALAR SCRIPT RETAIL.ADMIN_COMMANDS(CONNECTION_NAME VARCHAR(2000000))
EMITS(MESSAGE VARCHAR(2000000)) AS
import pyexasol
def run(ctx):
    c = pyexasol.connect(dsn=exa.get_connection(ctx.CONNECTION_NAME).address,
         user=exa.get_connection(ctx.CONNECTION_NAME).user,
         password=exa.get_connection(ctx.CONNECTION_NAME).password)
    stmt = c.execute("CREATE SCHEMA IF NOT EXISTS PYTHON_TEST_SCHEMA;")
    c.close()
    ctx.emit("Schema created");
/
```
  Time to test the new RETAIL.ADMIN_COMMANDS UDF (script). Here is the SQL to execute as the SYS user, to build another test schema, "PYTHON_TEST_SCHEMA".

 
```sql
--===================================--
-- Test as SYS user
--===================================--
select RETAIL.ADMIN_COMMANDS('SYS_CONN') from dual; 

select * from exa_all_schemas where SCHEMA_NAME = 'PYTHON_TEST_SCHEMA'; -- confirm it was created!
```
  

## Continuing with Solution

### Create test user

As we approach the solution, we will introduce a new user name, "JOHN". John was top in his class of button-pushing monkeys, but can not be trusted with elevated database privileges. Here we set up "JOHN" and allow him to connect to the database. This will also be our first test of privileges, using "JOHN"'s credentials. Be sure you do not already have a user "JOHN" in your database. If so, please change "JOHN" to any user name you feel appropriate.


```sql
--DROP USER IF EXISTS JOHN CASCADE; -- Uncomment to reuse, if you are sure about dropping JOHN 
CREATE USER "JOHN" identified by "exasol"; 
GRANT CREATE SESSION TO JOHN;
```
### Test the new user

We suggest opening up a new session and running the next query, as once we impersonate JOHN, we will not be able to return to the SYS user. You can get around this by running (as the SYS user), "GRANT IMPERSONATION ON SYS TO JOHN". Continuing, as the user JOHN, we invoke the RETAIL.ADMIN_COMMANDS UDF.


```sql
--===================================--
-- This should NOT work >> insufficient privileges for calling script
--===================================--
IMPERSONATE JOHN;
select RETAIL.ADMIN_COMMANDS('SYS_CONN') from dual;
```
### Build a Lua script to execute the desired SQL

As the SYS user, we create a Lua script to accept parameters and run predefined SQL.


```sql
--===================================--
--Create the Lua script
--===================================--
--/
CREATE OR REPLACE SCRIPT RETAIL.ADMIN(in_schema, in_user, in_password, in_role) AS
  function cleanup()
    query([[DROP USER IF EXISTS :: u CASCADE ]], {u=in_user})
    query([[DROP ROLE IF EXISTS :: r CASCADE ]], {r=in_role})
    query([[DROP SCHEMA IF EXISTS :: s CASCADE]],{s=in_schema})
  end
  ret1, success1  = pquery([[CREATE SCHEMA IF NOT EXISTS ::s ]], {s=in_schema})
    if success1 then
     output("CREATE SCHEMA success")
    else
     output("CREATE SCHEMA failed")
     cleanup()
     exit()
  end
  ret2, success2  = pquery([[OPEN SCHEMA ::s ]],  {s=in_schema})
    if success2 then
     output("OPEN SCHEMA success")
    else
     cleanup()
     exit()
  end
  ret3, success3 =  pquery([[CREATE USER ::u IDENTIFIED BY ::p]], {u=in_user, p=in_password})
  if success3 then
     output("CREATE USER success")
  else
     output("CREATE USER failed")
     cleanup()
     exit()
  end
  ret4, success4 = pquery([[CREATE ROLE ::r ]], {r=in_role})
  if success4 then
    output("CREATE ROLE success")
  else
    output("CREATE ROLE failed")
    cleanup()
    exit()
  end
  results_table ={}
/
```
### Test the Lua script

Running as the SYS user, we test the Lua script. If you already have a schema named "TEST_SCHEMA" and/or have a user named, "TEST_USER", then please change the following test SQL to reflect the appropriate schema, role, and user, as they will be dropped first (If they exist) and then created.


```sql
--===================================--
--Test the lua script as SYS user
--===================================--
EXECUTE SCRIPT RETAIL.ADMIN ('TEST_SCHEMA', 'TEST_USER', 'exasol', 'TEST_ROLE') WITH OUTPUT;
```
 We can validate the Lua script worked by querying our system tables for the new schema, user, ...etc.


```sql
--===================================--
--Prove the Lua script created the objects
--===================================--
select 'SCHEMA NAME', SCHEMA_NAME from exa_all_schemas where SCHEMA_NAME = 'TEST_SCHEMA'
UNION ALL -- confirm it was created!
select 'USER NAME', USER_NAME from exa_all_users where USER_NAME = 'TEST_USER'
UNION ALL
select 'ROLE NAME', ROLE_NAME from exa_all_roles where ROLE_NAME = 'TEST_ROLE';
```
### Recapping work so far and cleaning up SQL objects

So far, we have created a user JOHN, built and tested the Lua script. Time to clean up, as we will be testing, again and again, to verify functionality and see that the appropriate privileges either prevent or allow the user JOHN to run the designated scripts.


```sql
--===================================-- 
--Clean up 
--===================================-- 
drop schema TEST_SCHEMA cascade; 
drop user TEST_USER cascade; 
drop role TEST_ROLE cascade;
```
### Build the Python wrapper or proxy UDF

Continuing, we now build the Python wrapper or proxy UDF which will invoke the Lua script. This Python script uses the connection we created to inherit the elevated (SYS user) privileges. We do not have to grant any additional escalated privileges to the script, as it connects back to the database as the SYS user. Please notice the credentials are masked.


```sql
--===================================--
-- Create the Python wrapper or proxy script
--===================================--
 --/
CREATE OR REPLACE PYTHON3 SCALAR SCRIPT RETAIL.ADMIN_USER_COMMANDS(
in_schema VARCHAR(2000000) -- new schema
,in_user VARCHAR(2000000) -- new user
,in_password VARCHAR(2000000) -- user password
,in_role VARCHAR(2000000)) -- new role

EMITS(MESSAGE VARCHAR(2000000)) AS
import pyexasol
def run(ctx):
    CONNECTION_NAME = 'SYS_CONN'
    c = pyexasol.connect(dsn=exa.get_connection(CONNECTION_NAME).address,
         user=exa.get_connection(CONNECTION_NAME).user,
         password=exa.get_connection(CONNECTION_NAME).password)

    stmt = c.execute(f"EXECUTE SCRIPT RETAIL.ADMIN ('{ctx.in_schema}', '{ctx.in_user}', '{ctx.in_password}', '{ctx.in_role}') WITH OUTPUT")
    row = stmt.fetchall()
    
    for i in row:
        ctx.emit(str(i[0]))
    c.close()
/
```
### Test the new Python UDF

We test the Python script (UDF - notice we do a "SELECT")  as the SYS user.


```sql
--===================================--
-- Run as the SYS user
--===================================--
select RETAIL.ADMIN_USER_COMMANDS('TEST_SCHEMA', 'TEST_USER', 'exasol', 'TEST_ROLE') from dual;
```
### Confirm the solution

Let's confirm the results by querying the system tables for the new database objects. The next query is run as the SYS user. 


```sql
--===================================--
-- Confirm the Python UDF worked by querying the system tables
--===================================--
select 'SCHEMA NAME', SCHEMA_NAME from exa_all_schemas where SCHEMA_NAME = 'TEST_SCHEMA'
UNION ALL -- confirm it was created!
select 'USER NAME', USER_NAME from exa_all_users where USER_NAME = 'TEST_USER'
UNION ALL
select 'ROLE NAME', ROLE_NAME from exa_all_roles where ROLE_NAME = 'TEST_ROLE';
```
### Clean up objects created by the solution

We clean up the new objects.


```sql
--===================================--
--clean up
--===================================--
drop schema TEST_SCHEMA cascade;
drop user test_user cascade;
drop role test_role cascade;
```
### Test as user JOHN to demonstrate insufficient privileges (so far)

Let's test as user JOHN. The first test is to ensure JOHN is unable to run the Lua script. If you have not opened a new session as user JOHN, we suggest you do so now, as once the command IMPERSONATE JOHN is executed, you will not be able to return to user SYS, unless you have executed, "GRANT IMPERSONATION ON SYS TO JOHN". 


```sql
--impersonate JOHN; -- Uncomment if you have granted impersonation on SYS to JOHN. Otherwise, we assume you have a second session open and running as the user JOHN.
--===================================--
--Test Lua script as John to validate insufficient permissions
--===================================--
EXECUTE SCRIPT RETAIL.ADMIN ('TEST_SCHEMA', 'TEST_USER', 'exasol', 'TEST_ROLE') WITH OUTPUT; 
--Should get error >>  insufficient privileges for executing a script
```
Next, we validate JOHN is unable to execute the Python UDF.


```sql
--===================================--
--Test the python script as John to validate insufficent privileges.
--===================================--
select RETAIL.ADMIN_USER_COMMANDS('TEST_SCHEMA', 'TEST_USER', 'exasol', 'TEST_ROLE') from dual; 
--Should get error >> insufficient privileges for calling script
```
### Grant JOHN needed permissions

Returning to our session running as SYS, we grant JOHN the appropriate permissions. If you have NOT revoked USE ANY SCHEMA from PUBLIC, then the "GRANT USAGE ON SCHEMA RETAIL TO JOHN;" is not needed. Running it anyway will not hurt anything.


```sql
--===================================--
--Run as SYS user to grant John only needed permissions
--===================================--
--impersonate sys; -- only needed if you switching between SYS and JOHN in same session.
GRANT EXECUTE ON RETAIL.ADMIN_USER_COMMANDS TO JOHN;
GRANT USAGE ON SCHEMA RETAIL TO JOHN;
GRANT ACCESS ON CONNECTION SYS_CONN FOR SCRIPT RETAIL.ADMIN_USER_COMMANDS TO JOHN;
```
### Showtime! Run the solution as JOHN

As user JOHN, we regression test JOHN invoking the Lua script - which should fail.


```sql
--===================================--
--Test again as John, which demonstrates the permissions we just granted as user SYS.
--===================================--
-- IMPERSONATE JOHN; -- Uncomment if you have granted impersonation on SYS to JOHN. Otherwise, we assume you have a second session open and running as the user JOHN.
--===================================--
--Test John invoking the Lua script >> Should get error -- insufficient privileges for executing a script
--===================================--
EXECUTE SCRIPT RETAIL.ADMIN ('TEST_SCHEMA', 'TEST_USER', 'exasol', 'TEST_ROLE') WITH OUTPUT;
```
Now it's time to test the whole solution running as user John. 


```sql
--===================================--
--As user John, try invoking the python script, which SHOULD work!
--===================================--
select RETAIL.ADMIN_USER_COMMANDS('TEST_SCHEMA', 'TEST_USER', 'exasol', 'TEST_ROLE') from dual;
```
### Confirm results

Still with us? As the SYS user, confirm JOHN successfully invoked the Python wrapper UDF, confirm JOHN does not have any elevated permissions, other than what is needed to execute (invoke) the Python wrapper UDF.


```sql
--===================================--
-- Confirm the Python UDF worked by querying the system tables
--===================================--
select 'SCHEMA NAME', SCHEMA_NAME from exa_all_schemas where SCHEMA_NAME = 'TEST_SCHEMA'
UNION ALL -- confirm it was created!
select 'USER NAME', USER_NAME from exa_all_users where USER_NAME = 'TEST_USER'
UNION ALL
select 'ROLE NAME', ROLE_NAME from exa_all_roles where ROLE_NAME = 'TEST_ROLE';

 

--===================================--
--As the SYS user, CONFIRM JOHN does NOT have CREATE SCHEMA, CREATE USER, CREATE ROLE PRIVS
--===================================--
-- IMPERSONATE SYS; -- Uncomment if you have already granted impersonation on SYS to JOHN. Otherwise, we simply run this in the session for user SYS.
select * from EXA_DBA_OBJ_PRIVS where grantee = 'JOHN';
select * from EXA_DBA_SYS_PRIVS where grantee = 'JOHN';
```
## Epilogue

### Regression Test of JOHN's privileges

Complete JOHN's privileges test by trying to create some database objects. The next set of queries are invoked as the user JOHN and should all fail on insufficient privileges. If you have a separate session running as the user JOHN, then JOHN's session should be attempting the following queries.


```sql
--===================================--
--Confirm privilege testing by running these queries as John
--===================================--
-- IMPERSONATE JOHN; -- Uncomment is you are running solution in same session as SYS.
create schema if not exists JOHN; -- >> fail!
create user johns_friend identified by "exasol"; -- >> Fail!
create role johns_role; -- >> fail!
```
### Recapping from the Prologue - point #2

When concluding your development testing, be sure and execute either "DROP USER JOHN CASCADE " or "REVOKE IMPERSONATION ON SYS FROM JOHN". Otherwise, you have a gaping security issue in your development region. 


## Additional References

[Hiding credentials](https://docs.exasol.com/database_concepts/udf_scripts/hide_access_keys_passwords.htm) 

[Python Connections](https://docs.exasol.com/database_concepts/udf_scripts/python.htm#AccessingConnectionDefinitions) 

[Lua Connections](https://docs.exasol.com/database_concepts/udf_scripts/lua.htm#AccessingConnectionDefinitions) 

[General Connection info](https://docs.exasol.com/sql/create_connection.htm) 

[Scripting Basics](https://docs.exasol.com/database_concepts/scripting.htm) 

[UDF Basics](https://docs.exasol.com/database_concepts/udf_scripts.htm) 

[Query and PQuery functionality](https://docs.exasol.com/database_concepts/scripting/db_interaction.htm) 

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 