# Database Size 
## Background

This article explains more about the database size and what the values in EXA_ALL_OBJECT_SIZES mean.

## Explanation

The database size can be calculated on the basis of the following system dictionaries: EXA_ALL_OBJECT_SIZES or EXA_DBA_OBJECT_SIZES.

The dictionary lists all tables and schemas. Please note, the size of an object of the type 'SCHEMA' will be calculated as a sum of the sizes of all the objects in this schema. For views, functions, etc., the size represents the corresponding text size.

**RAW_OBJECT_SIZE** specifies the logical object size based on both data types and content. The value is calculated as a sum of sizes of stored data:

* fixed size type: determined by the [size of the type](https://docs.exasol.com/sql_references/data_types/data_type_size.htm#OtherTypes) * number of rows
* variable size type (varchar) –› estimated for performance reasons.

**MEM_OBJECT_SIZE** specifies the real size of the database object. The value is calculated as a sum of the following:

* a sum of all stored values after compression
* structural overhead, e.g. length information for a VARCHAR value
* overhead for replication  
Replication: Table content will be held in RAM on each node for better performance. This applies only to small tables (< 100.000 rows).

Please note, that for a new table some data blocks will be reserved. Therefore, MEM_OBJECT_SIZE of empty or very small tables can be bigger than RAW_OBJECT_SIZE. This does not imply a bad data compression ratio.

These system dictionaries provide you the total size of database objects in the cluster.

### Example: Objects in the schema 'EXAMPLES'


```"code-sql"
        OBJECT_NAME              OBJECT_TYPE RAW_OBJE MEM_OBJE
        ------------------------ ----------- -------- --------
        TESTADR                  TABLE         492836  2615072
        ITEMS                    TABLE           1120    23489
        PAYMENTS                 TABLE            208    13956
        PRODUCTS                 TABLE           1191   230942
        NEW_CITIES               TABLE            132    80336
        V_PRODUCT_ORDERING       VIEW             578      578
        V_CUSTOMERS              VIEW             431      431
        V_PRODUCT_RATING_MONTHLY VIEW             755      755
        CUSTOMER_MOVES           TABLE              0    13920
        MYMAX                    FUNCTION         290      290
        DAYS_BETWEEN             FUNCTION         402      402
        COUNTRIES                TABLE             64    74655
        NEW_CUSTOMERS            TABLE            117   217756
        CITIES                   TABLE            167    80336
        ORDERS                   TABLE            399    13996
        TESTADR_CLEANSED         TABLE          41770  1822724
        CUSTOMERS                TABLE            365   222986
        RETURNED_ITEMS           TABLE            178    92179
        V_ORDERS                 VIEW             648      648
        V_RETURNS                VIEW             713      713
        V_PAYMENTS               VIEW             472      472
        V_CUSTOMER_RAITING       VIEW             861      861
        V_TRANSACTIONS           VIEW             615      615
        LAG                      TABLE             45     9299
        MYFUNCS                  PACKAGE          208      208
```
## Data distribution

You can check the data distribution of a table by using an iproc()-function:

#### Example: Using of iproc()-function


```"code-sql"
SELECT count(*), iproc() FROM mytable GROUP BY iproc() ORDER BY 2; 
```

```"code-sql"
        COUNT(*)            IPROC
        ------------------- -----
                    5327099     0
                    5325780     1
                    5333799     2
                    5319445     3     
```
## Additional References

* [EXA_DBA_OBJECT_SIZES](https://docs.exasol.com/sql_references/metadata/metadata_system_tables.htm#EXA_DBA_OBJECT_SIZES)
* [Data Types](https://docs.exasol.com/sql_references/data_types/datatypesoverview.htm)
* [Data Type Sizes](https://docs.exasol.com/sql_references/data_types/data_type_size.htm)
* [Distribution Keys](https://docs.exasol.com/sql/alter_table(distribution_partitioning).htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 