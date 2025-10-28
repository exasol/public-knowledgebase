# Metadata for Views

## Question

We’re looking for a way to automatically collect metadata about database views, particularly after the underlying tables have been refreshed. We are interested in basic statistics such as row counts, data volume and field-level statistics. Is there a built-in feature in Exasol, similar to the EXA_ALL_TABLES system table for tables, that can provide this type of metadata for views?

## Answer

### Limitations of Metadata Reporting for View Statistics in Exasol

In Exasol, the metadata table EXA_DBA_OBJECT_SIZES reports the raw_size for views and scripts as the length of their corresponding SQL or script text. However, unlike EXA_ALL_TABLES—which provides statistics such as row counts for tables (TABLE_ROW_COUNT) - there is no automatic system table that supplies similar statistics for views.

### Understanding the Dynamic Nature of Views in Exasol

Views in Exasol are always virtual. They don’t store any data themselves—just the SQL query definition.
The data that a view returns is generated on-demand each time you run a query against it. This means the results can change immediately whenever the underlying tables are updated, inserted into, or deleted from.
Because of this dynamic nature, any stored metadata (like row counts or total data volume) would quickly become outdated or misleading.
Collecting and persisting this metadata for every view would require Exasol to constantly re-calculate statistics for every change—which would be very resource-intensive, especially in busy systems.

### Note

The metadata automation you seek—dynamic row count and size—is not a built-in feature for standard views in most databases. It becomes a native feature only when you switch from a Standard View to a Materialized View, as Materialized Views are physical, persistent data objects that the database is designed to monitor and report on.

Materialized views (which do store their results and can have persistent statistics) are not supported in Exasol. Only virtual views exist here.

### Summary

There is no built-in, automated metadata/statistics for views in Exasol (or most other databases), because views do not store data.
You can gather these statistics manually via SQL queries.
Some customers automate this by running scheduled scripts and storing the results in their own reporting tables.

## References

* [Documentation of EXA_DBA_OBJECT_SIZES](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_dba_object_sizes.htm)
* [Documentation of EXA_ALL_TABLES](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_all_tables.htm)
* [Query to control the size of all objects in the database](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_all_tables.htm](https://github.com/exasol/public-knowledgebase/blob/main/Database-Features/query-to-control-the-size-of-all-objects-in-the-database.md))
* [CHANGELOG: Raw size of scripts, views, and functions set to 0 bytes](https://exasol.my.site.com/s/article/Changelog-content-11369?language=en_US)
  
*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
