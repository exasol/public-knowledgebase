# Permission Errors with Views 
## Problem

A user may report that they are not able to select views due to permission errors. These errors can occur during view creation or on SELECT

## Diagnosis

Usually, when there are permission problems with views, you would see an error message such as:


```markup
[Code: 0, SQL State: 42500]  insufficient privileges for SELECT on table ...
```
or


```markup
[Code: 0, SQL State: 42500]  insufficient privileges for SELECT on table : 
USAGE on schema ... needed. 
```
or


```markup
[Code: 0, SQL State: 42500]  insufficient privileges: SELECT on table ... 
must be grantable for ... (Session: 1680100781957054464)
```
## Explanation

Permissions on views behave differently compared to permissions on other objects because views can serve as an abstraction layer. In most use cases, the users are only able to select a view, which sometimes selects only a subselect of the data. It is common that the end-users do not have SELECT privileges on the underlying tables. For this reason, the views are always executed with the permissions of the **owner**, not the person who is executing the statement. This construct enables that end-users can still SELECT views, without needing permissions on the underlying objects. 

## Recommendation

When confronted with these errors, you should first check who is the owner of the view. You can do this by checking the owner of the schema, in which the view was created:


```markup
SELECT SCHEMA_NAME, SCHEMA_OWNER FROM EXA_SCHEMAS 
WHERE SCHEMA_NAME = '<Schema name>';
```
Once you find out the owner, you should verify the system and object privileges of this owner by checking EXA_DBA_OBJ_PRIVS and EXA_DBA_SYS_PRIVS:


```markup
SELECT * FROM EXA_DBA_OBJ_PRIVS WHERE GRANTEE = '<Schema Owner>';  
SELECT * FROM EXA_DBA_SYS_PRIVS WHERE GRANTEE = '<Schema Owner>';
```
When the owner of a schema is a role, the privileges of the role are checked. Even if a member of the role has additional privileges, since the owner of the schema is the role, the additional privileges of the user are not relevant. If the owner has additional privileges because they are members of other roles, you may need to check those permissions as well. 

To fix the error, you can grant the necessary object privileges on the owner of the schema. Afterwards, the view can be created and you are able to SELECT it. 

In case of the third error, "**SELECT ON TABLE ... must be grantable ...**":

This occurs because, even though the owner is able to select the underlying tables and objects, it does not mean that the owner is allowed to grant this object to other people. In this scenario, granting on a view is essentially granting a SELECT on the underlying objects to someone else. When the object is in the same schema, this is okay because the owner of the view and the underlying objects are the same (meaning the owner is able to decide if other people should select this object). In order to resolve this error, the **owner** of the schema needs to either have the SELECT ANY TABLE privilege, or also be the owner of the other schema which is referenced in the view.


```markup
GRANT SELECT ANY TABLE TO '<Schema owner>';  
ALTER SCHEMA <schema name> CHANGE OWNER <owner name>;
```
## Additional References

* [Permissions](https://docs.exasol.com/database_concepts/privileges.htm)
