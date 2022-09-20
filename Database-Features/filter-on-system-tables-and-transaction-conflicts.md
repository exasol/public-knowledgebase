# Filter on system tables and transaction conflicts 
## Background

Transaction conflicts, WAIT FOR COMMIT or ROLLBACK, each of them is possible. When querying system tables, read locks are implicitly set as follows:


```"code-sql"
SELECT * FROM EXA_DBA_TABLES;       -- readlock on all tables  SELECT * FROM EXA_DBA_TABLES  WHERE TABLE_SCHEMA  = 'SCHEMA1';   -- readlock on tables in SCHEMA1  SELECT * FROM EXA_DBA_TABLES  WHERE TABLE_SCHEMA  = 'SCHEMA1' AND TABLE_NAME = 'TABLE1';        -- readlock on table SCHEMA1.TABLE1 
```
This holds even for more complex filters if the following conditions are met:  
1) The system table (in this case EXA_DBA_TABLES) is the only one used in the query.  
2) The system table appears no more than once in the query (views built on top of this table, e.g. EXA_USER_TABLES, count as well)  
3) Only filters which meet the following requirements are evaluated without read-locking all objects contained in the system table (Filter Type A):  
a) Only one column is used in the filter  
b) This column is filterable (e.g. table_schema, table_name)  
c) The filter contains no lookups or references to other tables

## Explanation

If filters that violate the constraints above (Type B) are used, we distinguish two cases:  
1) Filters of type A and B are combined via AND on the highest filter level: In this case, only objects that passed type A filters are read-locked.  
2) Filters of type A and B are combined via OR on the highest filter level: In this case, all objects contained in the system table are read-locked.

Remark: In database versions before EXASolution 4.2.5, it may happen that unexpected read-locks are set when querying particular system tables which in fact are views (e.g. EXA_ALL_TABLES)

## Additional References

[Transaction-conflicts-for-mixed-read-write-transactions](https://community.exasol.com/t5/database-features/transaction-conflicts-for-mixed-read-write-transactions/ta-p/2143) 

[EXASOL-2124](https://www.exasol.com/support/browse/EXASOL-2124) 

[Transaction-system](https://community.exasol.com/t5/database-features/transaction-system/ta-p/1522) 

[Transaction_management.htm](https://docs.exasol.com/database_concepts/transaction_management.htm) 

