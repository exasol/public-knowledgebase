# Details on DELETE Operations 
## Background

The [DELETE](https://docs.exasol.com/sql/delete.htm) command can be used to remove data from a table. In Exasol, the DELETE command can trigger different processes based on the table statistics. 

## Explanation

The delete operation ensures the removal of data from tables. It works by simply marking the affected rows as deleted, without actually removing them physically from the table. This means that the data is still there, but it is simply ignored by the subsequent queries. From a performance perspective, the DELETE is normally very fast because no data is actually moved around. However, once a certain percentage (25%) of the table has been deleted, the DELETE will trigger a REORGANIZE.  

This method ensures that most DELETE operations are very fast at the expense of some added space needed because the data blocks still exist on the disk, even though they are not accessible. However, once this 25% threshold is reached, the next DELETE will take longer because the data will be physically removed.

### How to determine the percentage of deleted rows

To see what percentage of data is marked as deleted in a table, please see the DELETE_PERCENTAGE column in EXA_*_TABLES.

### Reorganize

While delete is very fast, it does present a drawback: data that is no longer needed is still stored leading to some extra memory usage. To limit this drawback, whenever too many rows are deleted, the table is "reorganized" by physically replacing the deleted rows with non-deleted ones. After the reorganize is completed, the table contains no rows that are marked as deleted. Moreover, all the indices of the affected table are dropped and created again.

**Performance:**
Normally, the reorganize operation is an expensive operation. This is because it typically needs to move a lot of data around to replace the rows marked as deleted with non-deleted rows. It essentially means that the full table is scanned and a lot of write operations take place on each column (proportional with the amount of deleted rows). Furthermore, the fresh index creation adds some extra time.

**Notes**

* While reorganization is an expensive operation, its cost is amortized over many deletes.
* Reorganize is triggered by default when a quarter of the rows are deleted. This may lead to a perceived decrease in performance when it happens, particularly for small deletes (i.e. deleting a couple of rows takes a long time). To alleviate this problem, it is possible to trigger the reorganize operation explicitly:


```"code-sql"
reorganize table t 
```
* By default the reorganize command will not trigger a table reorganize if the number of rows marked as deleted is smaller than 12.5% - in this case, the system recognizes that the number of deleted rows is too small and a reorganize is likely to only incur unnecessary performance penalties. To trigger a reorganize even, in this case, it needs to be explicitly enforced:


```"code-sql"
reorganize table t enforce
```
### Delete versus Reorganize

The table below summarizes the discussion above

|   |Delete   |Reorganize   |
|---|---|---|
|**Semantics**   |Marks rows as deleted, data is not removed   |Physically removes data from the tables   |
|**Occurrence**   |Whenever data is deleted (delete or merge)   |When more than 25% of rows are marked as deleted or when explicitly triggered   |
|**Performance**    |Very Fast   |Slow, needs to reorganize all the columns and re-create the indices   |

## Additional Notes

When many deletes are expected, an explicit reorganize of the affected tables should improve performance; for instance, such a pre-emptive reorganize can be done when the system is not under heavy usage.

## Additional References

* [DELETE Syntax](https://docs.exasol.com/sql/delete.htm)
* [REORGANIZE Syntax](https://docs.exasol.com/sql/reorganize.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 