# No default DRIVER registered (not written in the Default JDBC Driver Path)

## Problem

We have stored the driver in **bucketfsfordrivers/mydrivers/**. However, the connection does not work and the following error message appears:

```text
[Code: 0, SQL State: ETL-1] No default DRIVER registered for jdbc:postgresql://xyz.intern:1234/abc.
Please specify DRIVER or add a default via EXAoperation
```

## Solution

By default, Exasol expects JDBC drivers to be in: */buckets/bfsdefault/default/drivers/jdbc/*.  In this case, however, the JDBC information should be read from another bucketfs.

Thus, check if it is in the list of URLs used to search for JDBC drivers:

```text
root@n11:~#  confd_client db_info db_name: <database> | grep bucket
```

Example:

```text
root@n11:~#  confd_client db_info db_name: MYDB | grep bucket
    bucket: default
    bucketfs: bfsdefault
```

If it is not listed there add it like this in our example:

(1,)  The database must be offline to change its configuration, thus stop database:

```text
confd_client db_stop db_name: MYDB
```

(2.) Set List of URLs used to search for JDBC drivers with jdbc_urls

```text
confd_client db_configure db_name: MYDB jdbc_urls: ['bucketfs://bucketfsfordrivers/mydrivers/jdbc']
```

(3.) Start database

```text
confd_client db_start db_name: MYDB
``` 

(4.) Test, if custom bucket is listed: 

```text
root@n11:~#  confd_client db_info db_name: MYDB | grep bucket
    bucket: mydrivers
    bucketfs: bucketfsfordrivers
    bucket: default
    bucketfs: bfsdefault
```

## References

* [db_configure](https://docs.exasol.com/db/latest/confd/jobs/db_configure.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
