# Synchronization of LDAP / Active Directory Groups and Members to Exasol Database Users and Roles 
## Background

With the help of the below scripts, you can set up an automatic synchronization of LDAP/AD Groups with Exasol users and roles. 

## Prerequisites

 You must first configure the database to accept LDAP authentication. To do this, go to EXAoperation and [shut down](https://docs.exasol.com/administration/on-premise/manage_database/start_stop_db.htm#DatabaseShutdown) the database in question. Once the database is shut down, you can edit the database and add the LDAP server in the field "LDAP Server URLs". The URL must start with ldap:// or ldaps://. Afterward, start the database back up. You can find more information [here](https://docs.exasol.com/sql/create_user.htm), which points to [edit_database.](https://docs.exasol.com/administration/on-premise/manage_database/edit_database.htm)Afterward, add the distinguished name of the corresponding LDAP (Active Directory) group as a comment on all database roles you want to synchronize with LDAP:
```markup
CREATE ROLE "EXAMPLE-READONLY";  
COMMENT ON ROLE "EXAMPLE-READONLY" IS 'cn=example-readonly,ou=groups,dc=ldap,dc=example,dc=org';   
CREATE ROLE "EXAMPLE-ADMIN";  
COMMENT ON ROLE "EXAMPLE-ADMIN" IS 'cn=example-admin,ou=groups,dc=ldap,dc=example,dc=org';
```
Finally, create a CONNECTION with your LDAP information. In this connection, you should configure the LDAP server (beginning with ldap:// or ldaps://), the user that will connect to the LDAP server and pull the information for the groups, and that user's password. The specified user should be able to read the properties of users and groups. You may need assistance from your Active Directory team to provide the appropriate user and password for building the connection. 


```markup
CREATE CONNECTION LDAP_SERVER TO 'ldap://<ldap_url>' 
user 'cn=admin,dc=ldap,dc=example,dc=org' 
identified by 'mysecretpassword'; 
```
Note: When testing the connection, if the connection fails with "Server not found", try replacing the <ldap_url> with the I.P. address and port. If Exasol was not configured to use your DNS servers, using the I.P. address and port is a common workaround, at least until you have successfully implemented the solution. Here is a simple example of how it would appear. 


```sql
create or replace connection test_ldap_server 
to 'ldap://192.168.1.155:389' 
user 'cn=admin,dc=manhlab,dc=com' 
identified by 'abc';
```
You can find more LDAP connection and authentication help here:

[Manual LDAP test](https://community.exasol.com/t5/database-features/manual-ldap-connection-test/ta-p/1679)       [Force create user when connection fails](https://community.exasol.com/t5/database-features/ldap-error-can-t-contact-ldap-server-use-force-option-to-create/ta-p/1888)      [LDAP authentication fails on distinguished-name](https://community.exasol.com/t5/connect-with-exasol/ldap-authentication-failed-for-distinguished-names-containing/ta-p/836) 

## How to Synchronize AD users and groups

## Step 1: Create Scripts

First, you must create the below scripts in the database. This script will perform the "searching" of the active directory to get the user attributes for a specific group.  The credentials you use to connect to the LDAP server to do the "searching" were defined in the connection above - this is to protect the username and password like described [here](https://docs.exasol.com/6.2/database_concepts/udf_scripts/hide_access_keys_passwords.htm).

The Lua script that is created will generate and execute CREATE/DROP USERs and GRANTs / REVOKEs, e.g. for each of the database roles that are marked like in the prerequisite. In particular, it finds the users/roles that are in the associated groups and compares what is in the database vs the AD group, and then performs the commands as needed.

**The scripts can be found in [Github](https://github.com/exasol/exa-toolbox/blob/master/utilities/ldap_sync.sql).**

## Step 2: Grant Permissions

If you are not running the scripts as a DBA, then you must grant the appropriate permissions on the scripts. In particular, you need to use the GRANT ACCESS syntax to allow the UDFs to read the credentials from the connection you created earlier:


```sql
GRANT EXECUTE ON EXA_TOOLBOX TO <user or role>; 
GRANT ACCESS ON CONNECTION LDAP_SERVER FOR EXA_TOOLBOX TO <user or role>;
```
## Step 3: Determine attributes to sync

You can use the LDAP_HELPER script to help determine which attributes in LDAP correspond to the list of users in the group and the usernames. These attributes are needed to perform the sync in the next step. The below commands will do this:


```sql
-- To find out which attributes contain the group members, you can run this:
select EXA_TOOLBOX.LDAP_HELPER('LDAP_SERVER', ROLE_COMMENT) from exa_Dba_roles where role_name = <role name>

-- To find out which attributes contain the username, you can run this:
select EXA_TOOLBOX.LDAP_HELPER('LDAP_SERVER', user_name) from exa_dba_connections WHERE connection_name = 'LDAP_SERVER'; 

-- For other purposes, you can run the script using the LDAP connection you created and the distinguished name of the object you want to investigate:
SELECT EXA_TOOLBOX.LDAP_HELPER(<LDAP connection>,<distinguished name>);
```
 **These scripts will read all attributes of the given object specified. You can also ask your AD admins to give you this information.**

## Step 4: Run the sync script regularly

You should execute this script periodically. The parameters of the script are:

* LDAP_CONNECTION - the connection to the LDAP server that you created in the prerequisites
* GROUP_ATTRIBUTE - the LDAP Attribute which contains all of the group members. In most cases, this is 'member' or 'memberOf' or something similar. If you are unsure, the default is 'member', and you can enter an empty string.
* USER_ATTRIBUTE - the LDAP attribute for the user containing their name. In most cases, this is 'uid' or 'sAMAccountName' or something similar. If you are unsure, the default is 'uid' and you can enter an empty string.
* EXECUTION_MODE - either DEBUG or EXECUTE. In DEBUG mode, all queries are rolled back at the end so you can test it without committing changes on the database

Some examples of the execution are below:


```sql
-- the below execution shows the parameter names
EXECUTE SCRIPT EXA_TOOLBOX."SYNC_AD_GROUPS_TO_DB_ROLES_AND_USERS" (LDAP_CONNECTION, GROUP_ATTRIBUTE, USER_ATTRIBUTE, EXECUTION_MODE)

-- the below uses the default values for GROUP and USER ATTRIBUTE
EXECUTE SCRIPT EXA_TOOLBOX."SYNC_AD_GROUPS_TO_DB_ROLES_AND_USERS" ('LDAP_SERVER','','','');

--the below specifies values (note this matches the execution as the above because member and uid are the default attributes)
EXECUTE SCRIPT EXA_TOOLBOX."SYNC_AD_GROUPS_TO_DB_ROLES_AND_USERS" ('LDAP_SERVER','member','uid','EXECUTE');

--the below specifies values that are different from the defaults
EXECUTE SCRIPT EXA_TOOLBOX."SYNC_AD_GROUPS_TO_DB_ROLES_AND_USERS"('LDAP_SERVER','memberOf','sAMAccountName', 'EXECUTE');

--the below runs the script in debug mode
EXECUTE SCRIPT EXA_TOOLBOX."SYNC_AD_GROUPS_TO_DB_ROLES_AND_USERS"('LDAP_SERVER','memberOf','sAMAccountName', 'DEBUG');
```

If you would like to automate this, you can trigger this script via cron job. You can read more about scheduling database queries [here](https://community.exasol.com/t5/connect-with-exasol/scheduling-database-jobs/ta-p/1586).

## Additional Notes

This script can be used as a starting point and may require some modification to meet your exact use case. 

## Additional References

* [Hiding Access Keys](https://docs.exasol.com/6.2/database_concepts/udf_scripts/hide_access_keys_passwords.htm)
* [Setting up LDAP](https://docs.exasol.com/6.2/sql/create_user.htm?Highlight=ldap#Authenti3)
* [LDAP Connection Test](https://community.exasol.com/t5/database-features/manual-ldap-connection-test/ta-p/1679)
* [Scheduling Database Jobs](https://community.exasol.com/t5/connect-with-exasol/scheduling-database-jobs/ta-p/1586)
* [Manual LDAP test](https://community.exasol.com/t5/database-features/manual-ldap-connection-test/ta-p/1679)
* [Force create user when connection fails](https://community.exasol.com/t5/database-features/ldap-error-can-t-contact-ldap-server-use-force-option-to-create/ta-p/1888)
* [LDAP authentication fails on distinguished-name](https://community.exasol.com/t5/connect-with-exasol/ldap-authentication-failed-for-distinguished-names-containing/ta-p/836)
