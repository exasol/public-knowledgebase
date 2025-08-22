# How to Import and Activate a SLC in Exasol DB

## Background

Exasol allows you to extend UDF capabilities using Script Language Containers (SLCs).
This powerful feature enables you to integrate almost any required libraries and language packages into your UDFs.

For detailed information and instructions about building and using your own SLC, please refer to the official GitHub repository: [SLC github](https://github.com/exasol/script-languages-release/blob/master/doc/user_guide/usage.md)

In this short tutorial, we focus on a specific use case: when Exasol prepares and provides a custom SLC and you only need to install it in your database.

## Prerequisites

- Write access to the BucketFS of your cluster.
- User DB/DBA access to the database, depending on whether an SLC should be activated on Session/System level.

## How to Import, Activate and Check SLC in your Exasol DB

### 1. Upload the provided SLC into the BucketFS

Download the provided SLC package. You may rename the file if you wish, but please keep the original *.tar.gz* extension. Upload this package into your cluster’s BucketFS in the bucket of your choosing. For the detailed instructions on managing files in BucketFS, please refer to the documentation here: [Manage Buckets and Files in BucketFS](https://docs.exasol.com/db/latest/administration/on-premise/bucketfs/file_access.htm)

### 2. Verify that the SLC is accessible by the DB

We recommend to confirm that the package was successfully uploaded in BucketFS and is accessible by the DB with help of the simple python udf [LS udf](https://docs.exasol.com/db/latest/administration/on-premise/bucketfs/database_access.htm).

The fact, that LS script lists your SLC package in the output, confirms that it is correctly uploaded and accessible by the DB.
For example:

```sql
-- Check the content of any path inside your DB's bucketfs
-- Example: LS udf shows the content of the "slc/python" folder in the "default" bucket of the "bfsdefault" bucketfs service

select vit.LS('/buckets/bfsdefault/default/slc/python');

+---------------------------------------------------+
| FILES                                             |
+---------------------------------------------------+
| template-Exasol-all-python-3.10_release           |
+---------------------------------------------------+
```

### 3.1 Activation of the SLC on the Session level

Once you have confirmed that the package is uploaded and accessible in your BucketFS, proceed to activate the SLC. You can activate it either at the session level or at the system level.
To activate the SLC only for the current session please run the following statement:

```sql
ALTER SESSION SET SCRIPT_LANGUAGES='<OTHER_SLCs> <LANGUAGE_ALIAS>=localzmq+protobuf:///<bucketfs-name>/<bucket-name>/<path-in-bucket>/<container-name>?lang=<language>#buckets/<bucketfs-name>/<bucket-name>/<path-in-bucket>/<container-name>/exaudf/exaudfclient';
```

Replace the following placeholders with the corresponding values in your system:

- **OTHER_SLCs** - Usually, you’ll want to keep the existing SLCs available. Simply list their definitions before your new language alias. To get the full definition of the current script languages in your DB, run the following SQL:

```sql
select * from exa_parameters where parameter_name = 'SCRIPT_LANGUAGES';
```

- **LANGUAGE_ALIAS** - Alias of the new script language to be used in UDFs. You can define multiple “versions” of the same language with different package configurations. If you want to replace an existing language with a new SLC, use its existing alias (for example, PYTHON3).
- **bucketfs-name** - bucketfs service where the SLC package resides
- **bucket-name** - bucket where the SLC package resides
- **path-in-bucket** - path inside the bucket where the SLC resides
- **container-name** - your SLC package name WITHOUT the extension
- **language** - the actual name of the scripting language. e.g. python, java, r

Example

```sql
-- get current script language configuration
select * from exa_parameters where parameter_name = 'SCRIPT_LANGUAGES';
+------------------+---------------------------------------------------------------+---------------------------------------------------------------+
| PARAMETER_NAME   | SESSION_VALUE                                                 | SYSTEM_VALUE                                                  |
+------------------+---------------------------------------------------------------+---------------------------------------------------------------+
| SCRIPT_LANGUAGES | R=builtin_r JAVA=builtin_java PYTHON3=builtin_python3         | R=builtin_r JAVA=builtin_java PYTHON3=builtin_python3         |
+------------------+---------------------------------------------------------------+---------------------------------------------------------------+

-- activating a new custom python SLC
ALTER SESSION SET SCRIPT_LANGUAGES='PYTHON3_CUSTOM=localzmq+protobuf:///bfsdefault/default/slc/python/template-Exasol-all-python-3.10_release?lang=python#buckets/bfsdefault/default/slc/python/template-Exasol-all-python-3.10_release/exaudf/exaudfclient R=builtin_r JAVA=builtin_java PYTHON3=builtin_python3 ';
```

### 3.2 Activation of the SLC on the System level

To permanently activate the SLC for the whole system use the same statement but with the "ALTER **SYSTEM**" clause

Example

```sql
ALTER SYSTEM SET SCRIPT_LANGUAGES='PYTHON3_CUSTOM=localzmq+protobuf:///bfsdefault/default/slc/python/template-Exasol-all-python-3.10_release?lang=python#buckets/bfsdefault/default/slc/python/template-Exasol-all-python-3.10_release/exaudf/exaudfclient R=builtin_r JAVA=builtin_java PYTHON3=builtin_python3 ';
```

### 4. Verify that the packages from the SLC could be used in your custom UDFs

For a complete list of the packages actually built in the SLC, you can check the SLC archive: navigate to *..\build_info\actual_installed_packages\release* inside the SLC archive.

For Python SLCs you can use the script below to check which packages are available for use in your DB. If the SLC is successfully activated, all its packages should appear in the output.

```sql
--/
CREATE OR REPLACE PYTHON3_CUSTOM SCALAR SCRIPT "GET_AVAILABLE_PYTHON_MODULES" () EMITS ("res" VARCHAR(4096) UTF8) AS
import pkgutil as pkgutil

def run(ctx):

  for module_name in pkgutil.iter_modules():
    ctx.emit(module_name[1])
/

--Example
select GET_AVAILABLE_PYTHON_MODULES();

+------------------+
|       res        |
+------------------+
| _aix_support     |
| _bootsubprocess  |
| _collections_abc |
| _compat_pickle   |
| _compression     |
| ...              |
+------------------+
```

## Additional References

- [Adding New Packages to Existing Script Languages](https://docs.exasol.com/db/latest/database_concepts/udf_scripts/adding_new_packages_script_languages.htm)
- [SLC github](https://github.com/exasol/script-languages-release/blob/master/doc/user_guide/usage.md)
- [LS udf](https://docs.exasol.com/db/latest/administration/on-premise/bucketfs/database_access.htm)
- [Python: Module Not Found](/Data-Science/python-module-not-found.md)  

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
