# No default DRIVER registered (not uploaded in the Default JDBC Driver Path)

## Problem

We have stored the driver in **/buckets/bucketfsfordrivers/mydrivers/jdbc**. However, the connection does not work and the following error message appears:

```text
[Code: 0, SQL State: ETL-1] No default DRIVER registered for jdbc:postgresql://xyz.intern:1234/abc.
Please specify DRIVER or add a default via EXAoperation
```

## Solution

By default, Exasol expects JDBC drivers to be in: **/buckets/bfsdefault/default/drivers/jdbc/**. In this case, however, the JDBC information should be read from another bucketfs **/buckets/bucketfsfordrivers/mydrivers/jdbc**

Thus, check if it is in the list of URLs used to search for JDBC drivers:

```text
root@n11:~#  confd_client -j db_info db_name: <database> | jq -r '.config.jdbc'
```

### Example

```text
root@n11:~# confd_client -j db_info db_name: MYDB | jq -r '.config.jdbc'
{
  "bucketfs": "bfsdefault",
  "bucket": "default",
  "dir": "drivers/jdbc",
  "additional_urls": []
}
```

If it is not listed there add it like this in our example:

### Steps

#### 1. The database must be offline to change its configuration, thus stop database

```text
confd_client db_stop db_name: MYDB
```

#### 2. Set List of URLs used to search for JDBC drivers with jdbc_urls

```text
confd_client db_configure db_name: MYDB jdbc_urls: ['bucketfs://bucketfsfordrivers/mydrivers/jdbc']
```

#### 3. Start database

```text
confd_client db_start db_name: MYDB
```

#### 4. Test, if custom bucket is listed

```text
root@n11:~# confd_client -j db_info db_name: MYDB | jq -r '.config.jdbc'
{
  "bucketfs": "bucketfsfordrivers",
  "bucket": "mydrivers",
  "dir": "jdbc",
  "additional_urls": []
}
```

## References

* Documentation of [db_configure](https://docs.exasol.com/db/latest/confd/jobs/db_configure.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
