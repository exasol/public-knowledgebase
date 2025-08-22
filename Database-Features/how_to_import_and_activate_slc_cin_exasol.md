# How to Import and Activate an SLC Container in Exasol DB

## Background

Exasol allows you to extend UDF capabilities using Script Language Containers (SLCs).
This powerful feature enables you to integrate almost any required libraries and language packages into your UDFs.

For detailed information and instructions about building and using your own SLC, please refer to the official GitHub repository: [SLC github](https://github.com/exasol/script-languages-release/blob/master/doc/user_guide/usage.md)

In this short tutorial, we focus on a specific use case: when Exasol prepares and provides a custom SLC and the customer only needs to install it in their own database.

## Prerequisites

- Access to the BucketFS of your cluster
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
```

### 3.1 Activation of the SLC on the Session level

Once you have confirmed that the package is uploaded and accessible in your BucketFS, proceed to activate the SLC. You can activate it either at the session level or at the system level.
To activate the SLC only for the current session please run the following statement:

```sql
ALTER SESSION SET SCRIPT_LANGUAGES='PYTHON3=localzmq+protobuf:///<YOUR_BFS_SERVICE>/<YOUR_BUCKET>/<PATH_INSIDE_THE BUCKET>/<SLC_PACKAGE_NAME>?lang=python#buckets/<YOUR_BFS_SERVICE>/<YOUR_BUCKET>/<PATH_INSIDE_THE BUCKET>/<SLC_PACKAGE_NAME>/exaudf/exaudfclient';

--replace the following placeholders with the corresponding values in your system.
--<YOUR_BFS_SERVICE> - bucketfs service where the SLC package resides
--<YOUR_BUCKET> - bucket where the SLC package resides
--<PATH_INSIDE_THE_BUCKET> - path inside the bucket where the SLC resides
--<SLC_PACKAGE_NAME> - your SLC package name WITHOUT the extension


--for example
ALTER SESSION SET SCRIPT_LANGUAGES='PYTHON3=localzmq+protobuf:///bfsdefault/default/slc/python/template-Exasol-all-python-3.10_release?lang=python#buckets/bfsdefault/default/slc/python/template-Exasol-all-python-3.10_release/exaudf/exaudfclient';
```

### 3.2 Activation of the SLC on the System level

To permanently activate the SLC for the whole system please run the following statement:

```sql
ALTER SYSTEM SET SCRIPT_LANGUAGES='PYTHON3=localzmq+protobuf:///<YOUR_BFS_CERVICE>/<YOUR_BUCKET>/<PATH_INSIDE_THE_BUCKET>/<SLC_PACKAGE_NAME>?lang=python#buckets/<YOUR_BFS_CERVICE>/<YOUR_BUCKET>/<PATH_INSIDE_THE BUCKET>/<SLC_PACKAGE_NAME>/exaudf/exaudfclient';

--replace the following placeholders with the corresponding values in your system.
--<YOUR_BFS_SERVICE> - bucketfs service where the SLC package resides
--<YOUR_BUCKET> - bucket where the SLC package resides
--<PATH_INSIDE_THE_BUCKET> - path inside the bucket where the SLC resides
--<SLC_PACKAGE_NAME> - your SLC package name WITHOUT the extension


--for example
ALTER SYSTEM SET SCRIPT_LANGUAGES='PYTHON3=localzmq+protobuf:///bfsdefault/default/slc/python/template-Exasol-all-python-3.10_release?lang=python#buckets/bfsdefault/default/slc/python/template-Exasol-all-python-3.10_release/exaudf/exaudfclient';

```

### 4. Verify that the packages from the SLC could be used in your custom UDFs

For a complete list of the packages actually built in the SLC, you can check the SLC archive: navigate to *..\build_info\actual_installed_packages\release* inside the SLC archive.

You can use the script below to check which packages are available for use in your DB. If the SLC is successfully activated, all its packages should appear in the output.

```sql
--/
CREATE OR REPLACE PYTHON3 SCALAR SCRIPT "GET_AVAILABLE_PYTHON_MODULES" () EMITS ("res" VARCHAR(4096) UTF8) AS
import pkgutil as pkgutil

def run(ctx):

  for module_name in pkgutil.iter_modules():
    ctx.emit(module_name[1])
/

--Example
select GET_AVAILABLE_PYTHON_MODULES();
```

## Additional References

- [Adding New Packages to Existing Script Languages](https://docs.exasol.com/db/latest/database_concepts/udf_scripts/adding_new_packages_script_languages.htm)
- [SLC github](https://github.com/exasol/script-languages-release/blob/master/doc/user_guide/usage.md)
- [LS udf](https://docs.exasol.com/db/latest/administration/on-premise/bucketfs/database_access.htm)
- [Python: Module Not Found](https://exasol.lightning.force.com/lightning/r/Knowledge__kav/ka0aV0000006C89QAE/view)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
