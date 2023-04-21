# Does Exasol index NULLS? 
## Question

Does Exasol index Null values?

## Answer

Yes, Exasol's indices contain NULL values. If you add a row with a NULL value in an index column, you will see an increase in MEM_OBJECT_SIZE in system table EXA_USER_INDICES. If there are a lot of NULLs, they will be compressed inside the index.

The NULLs of the index have rather few application scenarios as filters and joins typically omit NULLs (even before accessing the index). The NULLs are only relevant in some corner cases like UNION processing or so-called "OR NULL" equi-joins.

## Additional References

<https://www.exasol.com/support/browse/EXASOL-2197>

<https://exasol.my.site.com/s/article/NULL-in-Exasol>

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 