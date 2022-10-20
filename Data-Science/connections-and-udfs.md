# Connections and UDFs 
## Scope

When you are working with UDF's, you may want to access some credentials to connect to other sources, such as API's, S3 buckets, other databases, etc.  It's dangerous to write these in Plain Text within the context of the script, because anyone who can use the script is then also able to see the credentials that you hard-coded into the script. To solve this problem, you can save your credentials in [CONNECTION](https://docs.exasol.com/sql/create_connection.htm) objects. This is further described [here](https://docs.exasol.com/database_concepts/udf_scripts/hide_access_keys_passwords.htm). However, this requires some additional permissions. 

## Diagnosis

If you are trying to access connection credentials in a UDF, but do not have the correct permissions, you will see an error like this:


```markup
insufficient privileges for using connection <connection name> in script <script name>
```
This error could also occur when working with [Virtual Schemas](https://docs.exasol.com/database_concepts/virtual_schemas.htm) or [Cloud Storage UDFs](https://github.com/exasol/cloud-storage-extension)

## Explanation

The ability to use the credentials in a script is additional permission. Simply granting the connection to the user who executed the script is not enough. Instead, the ACCESS privilege is needed. These privileges are separated because ACCESS allows the username and password to be exposed in the script, which could be used maliciously. Simply granting the connection to someone only lets the user use it in IMPORT statements without exposing the username and password. 

## Recommendation

To fix this error, you can grant the ACCESS privilege to the user. This privilege can be called in various ways:

**Method 1 - least secure** - allows any script executed by this user to read the connection credentials


```markup
GRANT ACCESS ON <CONNECTION_NAME> TO <USER>;
```
**Method 2 - more secure** - allows all scripts in the specified schema executed by this user to read the connection credentials


```markup
GRANT ACCESS ON <CONNECTION_NAME> for <SCHEMA_NAME> TO <USER>;
```
**Method 3 - most secure** - allows only the named script executed by this user to read the connection credentials


```markup
GRANT ACCESS ON <CONNECTION_NAME> FOR <SCHEMA_NAME>.<SCRIPT_NAME> TO <USER>;
```
**Note- if you use method 3, any re-creation of the script (CREATE OR REPLACE) will drop also the privileges for this script**. So you would need to re-grant the access privileges. If you know that the script will be updated or re-created often, it may be better to grant it on the entire schema to avoid this problem.

## Additional References

* [Hiding Access Keys in Scripts](https://docs.exasol.com/database_concepts/udf_scripts/hide_access_keys_passwords.htm)
* [Access Connection Definitions in Lua](https://docs.exasol.com/database_concepts/udf_scripts/lua.htm#AccessingConnectionDefinitions)
* [Access Connection Definitions in R](https://docs.exasol.com/database_concepts/udf_scripts/r.htm#AccessingConnectionDefinitions)
* [Access Connection Definitions in Java](https://docs.exasol.com/database_concepts/udf_scripts/java.htm#AccessingConnectionDefinitions)
* [Access Connection Definitions in Python](https://docs.exasol.com/database_concepts/udf_scripts/python.htm#AccessingConnectionDefinitions)
* [Access Connection Definitions in Python 3](https://docs.exasol.com/database_concepts/udf_scripts/python3.htm#AccessingConnectionDefinitions)
