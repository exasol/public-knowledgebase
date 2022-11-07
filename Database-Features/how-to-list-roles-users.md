# How to List All Roles and Users

## Question
I'd like to see a list of all Exasol Roles and Users in the same table.

## Answer
There are a few ways to do this.  The first is:
> select * from exa_dba_role_privs;  

In this table GRANTEE is the User, and GRANTED_ROLE is the role.

You could also draw from a few other tables:
> select role_name as roles_and_users from exa_all_roles  
union all  
select user_name from exa_dba_users;