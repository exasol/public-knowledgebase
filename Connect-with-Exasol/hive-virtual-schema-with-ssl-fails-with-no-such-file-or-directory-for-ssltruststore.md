# Hive Virtual Schema with SSL fails with `No such file or directory` for `SSLTrustStore`

## Symptoms

A Hive JDBC connection works successfully without SSL. After SSL is enabled, the following behavior can be observed:

- `CREATE CONNECTION` succeeds.
- `CREATE VIRTUAL SCHEMA` succeeds.
- Tables are visible in the Virtual Schema.
- Queries against the Virtual Schema fail.

Example:

```sql
CREATE OR REPLACE CONNECTION HIVE_SSL_CONN
TO 'jdbc:hive2://hive.example.com:10001/;
SSL=1;
transportMode=http;
httpPath=cliservice;
SSLTrustStore=/buckets/bfsdefault/buckethive/example-truststore.jks;
SSLTrustStorePwd=changeit'
USER 'example_user'
IDENTIFIED BY 'example_password';

CREATE VIRTUAL SCHEMA HIVE_VS
USING ADAPTER.HIVE_JDBC_ADAPTER
WITH
    CONNECTION_NAME = 'HIVE_SSL_CONN'
    SCHEMA_NAME = 'example_schema';
```

The Virtual Schema is created successfully, but querying a table returns an error similar to:

```text
ETL-5402: JDBC-Client-Error:
Connecting to 'jdbc:hive2://...'
failed:

[Cloudera][HiveJDBCDriver](500164)
Error initialized or created transport for authentication:

/buckets/bfsdefault/buckethive/example-truststore.jks

(No such file or directory)
```

## Cause

The error is **not** caused by SSL itself.

Instead, the Hive JDBC driver cannot access the truststore file referenced in the JDBC URL from the runtime environment where the query is executed.

When referencing files in Exasol, there are two different views of BucketFS.

### Logical BucketFS path

This is the path used by UDFs and adapter scripts.

```text
/buckets/bfsdefault/buckethive/example-truststore.jks
```

### Physical BucketFS location

This is the location where the file is actually stored on disk.

```text
/exa/data/bfsdefault/buckethive/example-truststore.jks
```

The Hive JDBC connection references the logical BucketFS path:

```text
SSLTrustStore=/buckets/bfsdefault/buckethive/example-truststore.jks
```

The reported error

```text
No such file or directory
```

indicates that the JDBC driver successfully parsed the connection string but could not open the truststore because the specified path does not exist in the runtime environment executing the query.

Without SSL, no truststore is required, so the connection succeeds.

When SSL is enabled, the JDBC driver attempts to load the truststore before establishing the TLS connection. Since the truststore cannot be resolved, the connection fails before any TLS handshake with Hive begins.

## Why metadata works but queries fail

Creating and using a Hive Virtual Schema involves two different phases:

1. Metadata access
2. Data access

Although both phases use the same connection definition, they are executed by different components inside Exasol.

### Metadata access

During `CREATE VIRTUAL SCHEMA`, the Java adapter connects to Hive to retrieve metadata such as schemas, tables, and column definitions.

This explains why the Virtual Schema can be created successfully and tables are visible.

### Data access

When data is queried, the adapter generates internal `IMPORT FROM JDBC` statements.

These statements are executed by **EXALoader**, which also uses the Hive JDBC driver.

Because EXALoader must also access the truststore specified in the JDBC URL, the truststore path must be available in its runtime environment.

As a result, metadata operations may succeed while actual queries fail because they are executed by different runtime components.

## Workaround

On **every** Exasol data node, create the corresponding logical BucketFS directory and create a symbolic link to the physical BucketFS location.

```bash
mkdir -p /buckets/bfsdefault/buckethive
cd /buckets/bfsdefault/buckethive

ln -s /exa/data/bfsdefault/buckethive/example-truststore.jks
```

Run these commands on **every data node** in the cluster.

If your deployment stores BucketFS in a different physical location, adjust the symbolic link target accordingly.

The important requirement is that the absolute path referenced in the JDBC URL resolves locally on every node that may execute an `IMPORT FROM JDBC`.

## Validate the workaround

Before recreating the Virtual Schema, verify the connection with a minimal `IMPORT FROM JDBC`.

```sql
SELECT *
FROM (
    IMPORT FROM JDBC AT HIVE_SSL_CONN
    STATEMENT 'SELECT 1'
);
```

If this succeeds with SSL enabled, retry creating or querying the Virtual Schema.

## Known limitations

- Manual modifications inside the COS namespace are required.
- The symbolic link must be created on every data node.
- When new data nodes are added to the cluster, the symbolic link must also be created on those nodes.

## References

* [Exasol BucketFS documentation](https://docs.exasol.com/db/latest/administration/on-premise/bucketfs/bucketfs.htm)
* [Exasol Virtual Schema documentation](https://docs.exasol.com/db/latest/database_concepts/virtual_schema/virtual_schema.htm)
* [Exasol IMPORT documentation](https://docs.exasol.com/db/latest/sql/import.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
