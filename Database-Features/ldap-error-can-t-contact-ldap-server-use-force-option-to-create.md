# LDAP error: Can't contact LDAP server, use FORCE option to create user 
## Problem

If you create a user using LDAP, a simple connection check to the LDAP server is performed. Exasol tries to connect to the LDAP server with a bogus user and checks that access is denied. This check might produce false negatives in complex LDAP setups, so the error message is thrown, although there is no real problem.

## Diagnosis

If you receive the following error, you may be affected:


```
ldap error: Can't contact LDAP server, use FORCE option to create user 
```
## Solution

1. Check with your LDAP team that the Exasol database can reach the LDAP server. You can find more information [here](https://community.exasol.com/t5/database-features/manual-ldap-connection-test/ta-p/1679)

2. If you are sure that there is no problem with your LDAP server, you can always create the user with the FORCE option. In this case, the connection check will not be performed:


```
CREATE USER myuser IDENTIFIED AT LDAP AS 'uid=me,ou=people,dc=ex,dc=de' FORCE; 
```
Please note that if there are problems with connecting to the LDAP server, the user will receive this error during login:
```markup
Connection exception - authentication failed.
```
You should only use the FORCE option with caution to prevent confusion from users trying to login.

## Additional References

* [CREATE USER Syntax](https://docs.exasol.com/sql/create_user.htm)
