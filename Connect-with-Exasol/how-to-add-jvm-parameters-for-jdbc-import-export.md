# How to add JVM parameters for JDBC IMPORT/EXPORT

## Background

You can pass required JVM arguments directly to the ExaLoader JVM by using a database parameter. This is useful when a JDBC IMPORT or EXPORT requires additional Java runtime options, such as `--add-opens`.

## Prerequisites

- SSH access to a node in the target Exasol cluster
- Permission to stop and start the database
- The database name that will run the JDBC IMPORT or EXPORT

## Procedure

### Step 1: Connect to a cluster node

Connect by SSH to one of the nodes in your Exasol cluster.

Example:

```shell
ssh <user>@<cluster-node-ip>
```

### Step 2: Review the current database parameters

Before making changes, check whether the database already has `-etlJdbcJavaEnv` configured.

```shell
confd_client db_info db_name: <database_name>
```

### Step 3: Stop the database

You must stop the database before adding the parameter.

```shell
confd_client db_stop db_name: <database_name>
```

### Step 4: Add the JVM parameter

To pass a single JVM argument to the ExaLoader JVM, run:

```shell
confd_client db_configure db_name: <database_name> params_add: '[-etlJdbcJavaEnv=--add-opens=java.base/java.nio=ALL-UNNAMED]'
```

If `-etlJdbcJavaEnv` is already set, for example for a custom heap size, combine the values by using `:;` as the delimiter:

```shell
confd_client db_configure db_name: <database_name> params_add: '[-etlJdbcJavaEnv=-Xmx2048M:;--add-opens=java.base/java.nio=ALL-UNNAMED]'
```

### Step 5: Start the database

Restart the database so the parameter takes effect.

```shell
confd_client db_start db_name: <database_name>
```

## Additional Notes

- This change requires a database restart, so plan downtime before applying it.
- The delimiter between multiple JVM arguments in `-etlJdbcJavaEnv` is `:;`.
- Replace `<database_name>` and `<cluster-node-ip>` in the examples with values from your environment.

## Additional References

- [JDBC IMPORT/EXPORT: Create and receive JDBC logs](jdbc-import-export-create-and-receive-jdbc-logs.md)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
