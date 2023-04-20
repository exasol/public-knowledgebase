# Data Distribution 
## Background

In Exasol, the data is automatically evenly distributed among each node. This distribution is random, however.  By specifying distribution keys, you can control how the data is distributed, which can lead to enormous performance improvements. 

The following command defines the data distribution by setting some columns as key and the table distribution and distributes the rows accordingly.


```"code-sql"
ALTER TABLE <table-name> DISTRIBUTE BY <column name(s)> 
```
If the chosen distribution key would lead to a considerable data unbalance, the database rejects such a distribution key. Of course, data inserted later could unbalance the table.

You can remove the set distribution attributes with the help of


```"code-sql"
ALTER TABLE <name> DROP DISTRIBUTION KEYS;
```
You can also set a distribution key also directly at the creation time of a table within the corresponding DDL-Statement. Inserted data will be automatically distributed according to the attributes set, thus there is no need to redistribute data later.


```"code-sql"
CREATE TABLE test1 (     c_id INT,     c_name varchar(40),     c_birthday date,     DISTRIBUTE BY c_id );   
```
## Best Practices

* Choose only one single distribution key unless all joins to the tables use the identical multi-column join key (e.g. combined primary / foreign key).
* At best choose primary keys or columns that don't contain many duplicate values for distribution key since they will probably be the best (i.e. most restrictive) join conditions in joins.
* If the tables are used in other queries you should choose a distribution key that is used in other joins as well. Even if those joins cannot be executed locally because the joined table might not be partitioned, the joins are a little faster with one table partitioned by part of the join condition.
* Don't choose any char / varchar columns for distribution key if possible.

## Propagation of a distribution key

At executing of the CREATE TABLE AS SELECT command, distribution attributes will be derived from the original table if possible. The distribution of the new table will be set automatically.

## Data Reorganization

After adding some nodes to your cluster, you can resume the work at once. These new nodes, however, have no data. Data distribution won't be adjusted automatically to shorten the downtime. You can choose then the suitable time slot and start data reorganization also according to the object priority.

The command REORGANIZE adjusts the data distribution taking into account new nodes. It ensures that the data is distributed according to the set key. You can reorganize single tables, whole schemas or the complete database.

You need to start this command only after a cluster enlargement, otherwise, the distribution will be maintained automatically.


```"code-sql"
REORGANIZE (TABLE| SCHEMA| DATABASE) 
```
Please note the following:

* the reorganization will be performed in any case table-wise. If you reorganize a schema or your complete database, each table will be committed automatically.
* reorganize sets a write-lock on the corresponding table (see [transaction-system](https://exasol.my.site.com/s/article/Transaction-System) for more details on Exasol's transaction management)
* reorganize re-creates all the indices
* reorganize uses a large amount of RAM for re-distributing of data and re-creating the indexes. Is the RAM not sufficient, data will be swapped on the disk. Please ensure, that your persistent data volume has enough free space.

## Additional References

* [Performance Guide - Distribution](https://docs.exasol.com/performance/best_practices.htm#DistributionKeys)
* [ALTER TABLE - DISTRIBUTE BY](https://docs-test.exasol.com/sql/alter_table(distribution_partitioning).htm)
* [CREATE TABLE Syntax](https://docs-test.exasol.com/sql/create_table.htm)
* [REORGANIZE Syntax](https://docs-test.exasol.com/sql/reorganize.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 