# Using LUA to display environment and session_id 
## Background

Verifying the environment your DB client is accessing can sometimes be tricky. Where do I find what version of Exasol am I running? Which user am I running as? We have a solution canned up to get you started and introduce you to the power of LUA.

## Prerequisites

1. You have access to an Exasol database.

2. You are running as SYS user (DBA account) to build the script.

## How to display your environment info using a LUA script

## Step 1

Create the LUA script


```markup
--/ CREATE OR REPLACE LUA SCRIPT "WHOAMI" () RETURNS ROWCOUNT AS output("Database Name:"..tostring(exa.meta.database_name)) output("Database Version:"..tostring(exa.meta.database_version)) output("Number of Nodes:"..tostring(exa.meta.node_count)) output("Current User:"..tostring(exa.meta.current_user)) output("Current Schema:"..tostring(exa.meta.current_schema)) output("Session_ID:"..tostring(exa.meta.session_id)) / 
```
## Step 2

Execute the script to display your environment info and session_id. Please note the suffix "with OUTPUT", which is required to see the scripts output.


```markup
EXECUTE SCRIPT  WHOAMI() with OUTPUT;
```
## Additional Notes

Once the script has been created, any user can execute it providing they have been granted CREATE SESSION and granted EXECUTE SCRIPT on the script listed above.

Example:


```markup
GRANT EXECUTE on SCRIPT RETAIL.WHOAMI to john;
```
## Additional References

<https://docs.exasol.com/database_concepts/udf_scripts/lua.htm>

<https://docs.exasol.com/database_concepts/scripting/db_interaction.htm>

<https://docs.exasol.com/database_concepts/database_users_roles.htm>

