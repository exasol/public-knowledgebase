# How-To Migrate Tables with Indices from one Exa Cluster to another 
## Background

If existing Exasol data should be migrated from a cluster to another (new) one, it could be desired to migrate the existing indexes as well (usually for performance reasons during production start).

In general it is sufficient to migrate the data from an existing Exasol cluster. Due to Exasol's Automatic Index Maintenance there is no need to include indexes in the migration process, see [Automatic indexes](https://www.exasol.com/resource/automatic-indexes-in-exasol/) 

Imagine an existing Exasol cluster reached its end-of-service date and the data will be migrated to a new Exasol cluster. If data (without indexes) is migrated to another Exasol cluster, the indexes will be created and maintained automatically. Indexes are created 'on-demand' - as soon as they are required for the execution of a query.

For example if the data is migrated to the new Exasol cluster during a downtime on a weekend there will be (nearly) no indexes until the execution of queries begins. On Monday morning the users execute their queries and Exasol will create any necessary index if it does not exist. This index creation leads to additional workload on the new cluster. If this additional resource consumption should be avoided the indexes can be included in the migration. 

## How-To Migrate Tables with Indices from one Exa Cluster to another

## Migration in general

The following script can be used to prepare table DDLs and IMPORT commands to move the data: <https://github.com/exasol/database-migration/blob/master/exasol_to_exasol.sql>

However, the DDL part of the above script maybe improved even further:

* Dependency-aware view DDL generation (with no need for manual addition of FORCE) is already addressed in the following article: [How to create DDL for Exasol support](https://exasol.my.site.com/s/article/How-to-create-DDL-for-Exasol-support) (for exactly one view).
* DDL for grants are covered by the following article: [Create DDL for the entire Database](https://exasol.my.site.com/s/article/Create-DDL-for-the-entire-Database)

So the output of the three script above may be picked up or modified to tailor particular needs.

## Include Indexes in migration

There are at least two options:

1. Move only tables (data)
2. Also recreate the indices.

If the same SQLs against the corresponding tables will be executed in the new cluster, Exasol would probably have to create almost the same set of indices because of JOINs. So manual index creation (in advance) might reduce workload during production period.


```"code-sql"
SELECT   
 'enforce ' || index_type || ' index ' ||' on "' || index_schema || '"."' || index_table || '"' 
 || REPLACE(REPLACE(remarks, 'GLOBAL INDEX'), 'LOCAL INDEX') || '; '   
 FROM sys.exa_dba_indices   
 WHERE 1=1   
 AND <your filters>   
;
```
## Additional References

[Automatic Indexes in Exasol](https://uhesse.com/2019/04/05/automatic-indexes-in-exasol/) 

[Automatic indexes](https://www.exasol.com/resource/automatic-indexes-in-exasol/) 

[Performance - Best Practices](https://docs.exasol.com/performance/best_practices.htm) 

[Github: Exasol to Exasol Migration](https://github.com/exasol/database-migration/blob/master/exasol_to_exasol.sql)

[How to create DDL for Exasol support](https://exasol.my.site.com/s/article/How-to-create-DDL-for-Exasol-support)

[Create DDL for the entire Database](https://exasol.my.site.com/s/article/Create-DDL-for-the-entire-Database)

