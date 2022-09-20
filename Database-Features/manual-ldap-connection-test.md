# Manual LDAP Connection Test 
## Problem

You have successfully created a LDAP user, but the user cannot log in.

There might be a configuration problem with your LDAP server, the distinguished name might be wrong or any other database independent problem.

## Solution

Try to connect/bind to your LDAP server with the ldapsearch command line tool. If you cannot connect with ldapsearch, the database won't be able to connect the LDAP user.  
Here is a simple example:


```
ldapsearch -v -x -D "uid=Ben,ou=People,dc=myserv,dc=com" -w my_password -H ldap://my_ldap_server.com
```
