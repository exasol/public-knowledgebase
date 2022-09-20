# Disappearing User Privileges/Permissions 
Suddenly the privileges you assigned to a user are no longer in place. You end up reapplying privileges to a user, that was set up correctly the day before. Here we look at 2 solutions, one as the schema owner and the other having privileges assigned to a persisting role. In this article, privileges and permissions mean the same thing, to make the read more intuitive.

## Scope

Having to reapply the same privileges to a user, after some job/workflow runs?

## Diagnosis

Do you suddenly receive the error message, "invalid privileges for {select | insert | delete}", when trying to run SQL that worked the day before?

## Explanation

Generally, here are how existing user privileges disappear:

1) The user is dropped and recreated, which loses all privileges.

2) Tables in the schema are being refreshed using the "CREATE OR REPLACE TABLE", such that REPLACE actually drops the table and all permissions, then CREATES a new table without any permissions.

3) Maybe someone is revoking privileges? Seems unlikely, but if you have auditing turned on, you can read EXA_DBA_AUDIT_SQL and search for words like "REVOKE".

## Recommendation

1) Consider making the SCHEMA OWNER a role. You can then assign the role to the user which keeps losing his permissions. As opposed to assigning user permissions,  grant the permissions to a role. If the user is being dropped and recreated, then all we need to do is assign them the proper role.

2) If suggestion 1 does not work for you, try GRANT USAGE and GRANT SELECT, INSERT, UPDATE, DELETE to the role.

**Examples:**


```sql
-- -- BEGIN SQL -- DROP SCHEMA IF EXISTS EXAMPLE CASCADE; DROP ROLE IF EXISTS EXAMPLE_OWNER CASCADE; DROP ROLE IF EXISTS EXAMPLE_USER_ROLE CASCADE; DROP USER IF EXISTS EXAMPLE_USER CASCADE; CREATE ROLE EXAMPLE_OWNER; CREATE ROLE EXAMPLE_USER_ROLE; CREATE USER EXAMPLE_USER IDENTIFIED BY "abc"; CREATE SCHEMA IF NOT EXISTS EXAMPLE; OPEN SCHEMA EXAMPLE; ALTER SCHEMA EXAMPLE CHANGE OWNER EXAMPLE_OWNER; CREATE OR REPLACE TABLE EXAMPLE.TABLE_1(COL1 INTEGER, COL2 VARCHAR(100)); INSERT INTO EXAMPLE.TABLE_1 values(1, 'Step 1'),(2, 'Step 2'),(3, 'Step 3'); GRANT IMPERSONATION ON SYS TO EXAMPLE_USER_ROLE; -- only needed for this test! -- -- Scenario 1 Put user into EXAMPLE_OWNER role and create / write / read tables -- The first step should fail on permissions, then, as a member of -- EXAMPLE_OWNER, demonstrate full permissions: -- IMPERSONATE EXAMPLE_USER; SELECT * FROM EXAMPLE.TABLE_1; IMPERSONATE SYS; GRANT EXAMPLE_OWNER to EXAMPLE_USER; IMPERSONATE EXAMPLE_USER; SELECT * FROM EXAMPLE.TABLE_1; INSERT INTO EXAMPLE.TABLE_1 values(4, 'EXAMPLE_USER WAS HERE'); DELETE FROM EXAMPLE.TABLE_1 where COL1 = 1; IMPERSONATE SYS; REVOKE EXAMPLE_OWNER FROM EXAMPLE_USER; -- -- Scenario 2 To retain permissions, GRANT USAGE ON SCHEMA to EXAMPLE_USER_ROLE and put EXAMPLE_USER in that role. -- Ensure user EXAMPLE_USER can only select/read/update/delete. -- GRANT USAGE ON SCHEMA EXAMPLE TO EXAMPLE_USER_ROLE; GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA EXAMPLE to EXAMPLE_USER_ROLE; GRANT EXAMPLE_USER_ROLE to EXAMPLE_USER; IMPERSONATE EXAMPLE_USER; INSERT INTO EXAMPLE.TABLE_1 values(5, 'EXAMPLE_USER WAS HERE'); DROP TABLE EXAMPLE.TABLE_1 CASCADE; -- Should be denied on insufficient privileges. IMPERSONATE SYS; -- DROP TABLE IF EXISTS EXAMPLE.TABLE_1 CASCADE; -- CREATE OR REPLACE TABLE EXAMPLE.TABLE_1(COL1 INTEGER, COL2 VARCHAR(100)); INSERT INTO EXAMPLE.TABLE_1 values(1, 'Step 1'),(2, 'Step 2'),(3, 'Step 3'); -- IMPERSONATE EXAMPLE_USER; INSERT INTO EXAMPLE.TABLE_1 values(6, 'EXAMPLE_USER RETAINS PERMISSIONS'); SELECT * FROM EXAMPLE.TABLE_1; -- IMPERSONATE SYS; REVOKE IMPERSONATION ON SYS FROM EXAMPLE_USER_ROLE; -- -- END OF SQL --
```
## Additional References

[Privileges-overview](https://community.exasol.com/t5/database-features/privileges-overview/ta-p/1498 "privileges-overview") 

[Using-scripts-to-replace-granting-users-special-privileges](https://community.exasol.com/t5/database-features/using-scripts-to-replace-granting-users-special-privileges/ta-p/6056) 

