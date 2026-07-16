# Unable to Connect to PostgreSQL

## Question

We just moved our Google Cloud environment to Frankfurt, and I am trying to restablish the setup.

One of the things is to let Exasol access a postgres database.

Exasol is on one VPC network peered to another network with Postgres. We haven't yet been able to access using interal IP, so we are using external IP. This worked in our previous setup in another region.

When trying to connect I get this error message. As I understand it, it sounds like the exasol session is denied access to an internal exasol resource. The session is running as SYS, so it has as much permission to everything as possible.

Any ideas as to what I can try to make this work.

```text
SQL Error [ETL-5]: JDBC-Client-Error: Connecting to 'jdbc:postgresql://<IP>:5432/metadata?currentSchema=analyticaldata' as user='postgres' failed:
SSL error: access denied ("java.io.FilePermission" "/home/exasolution/.postgresql/postgresql.crt" "read") (Session: 1690951028142374912)
```

Any help is greatly appreciated.

Exasol is installed as a community edition using the Exasol BYOL option in GCP marketplace. Postgres driver came with the installation.

Postgres is a CloudSQL.

## Answer

The driver needs additional permissions. Add line "NOSECURITY=YES" to driver's `settings.cfg` file (see [Add JDBC driver](https://docs.exasol.com/db/latest/administration/on-premise/manage_drivers/add_jdbc_driver.htm)).

## References

* [Add JDBC driver](https://docs.exasol.com/db/latest/administration/on-premise/manage_drivers/add_jdbc_driver.htm)
* [Upload PostgreSQL JDBC driver](https://docs.exasol.com/db/latest/loading_data/connect_sources/postgresql.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
