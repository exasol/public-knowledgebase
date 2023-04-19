# ROWID 
## Question

Is the ROWID always assigned in an ascending order?  
Is it possible to determine the sequence of inserted records with the ROWID?

## Answer

The ROWIDs of a table are managed by the DBMS. They are assigned in an ascending order per node and stay distinct within a table. For different tables, they could be the same.

DML statements such as UPDATE, DELETE, TRUNCATE or MERGE might internally reorder data storage, invalidating and reassigning all the ROWIDs. Contrary to that, structural table changes such as adding a column leave the ROWIDs unchanged. Altering **distribution keys** of or **reorganizing** a table will certainly reassign ROWID values.

Therefore the ROWID can't be used to determine the exact sequence or age of a record, it is designed to be a **short term** identifier for rows to be used for duplicate elimination.

The ROWID pseudo column can only be used on **table** objects, not on views or subselects. If you try it on a view, you will receive an appropriate error message

## Additional References

* [ROWID Syntax](https://docs.exasol.com/sql_references/functions/alphabeticallistfunctions/rowid.htm)
