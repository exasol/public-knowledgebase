# MySQL to Exasol Migration Lessons Learned 
Here is a list of lessons we learned while migrating our reporting tools from MySQL (5.6 with strict mode off) to Exasol.

Hopefully, this will be useful for others making the same transition:

1. MySQL supports both`--` and`#` for indicating SQL comments. Exasol only supports `--`
2. `'\n'`in MySQL strings is interpreted as a newline. In Exasol it's treated as a literal slash + n so instead you need to use a literal newline character
3. Identifier quoting in MySQL is``...``while in Exasol it is`"..."`
4. String quoting in MySQL is either `"..."` or`'...'`while in Exasol it is only `'...'`
5. In MySQL column Identifiers are case insensitive while table identifiers are case sensitive. In Exasol all identifiers are case sensitive. Furthermore, if the identifier is unquoted it is converted to all uppercase.
6. Keyword differences. Identifiers that are keywords must be quoted in both MySQL and Exasol however what qualifies as a keyword differs. e.g.`PATH`is a keyword in Exasol but not in MySQL. You can get a list of Exasol keywords via`SELECT keyword FROM exa_sql_keywords WHERE reserved = TRUE;`
7. There are many MySQL builtin functions that are supported in Exasol but under a different name or calling syntax. e.g.`REGEXP -> REGEXP_LIKE, DATE -> TO_DATE, TRIM, DAYOFMONTH -> DAY, UNIX_TIMESTAMP -> POSIX_TIME, DATABASE() -> CURRENT_SCHEMA, DATETIME -> TIMESTAMP, SYSTEM -> SESSIONTIMEZONE`etc.
8. There there are many MySQL builtin functions which do not have a direct equivalent in Exasol but which can be emulated via UDFs/Scripts e.g.`CONCAT_WS, FIELD, DAYOFWEEK,`etc
9. There are many of MySQL keywords which have no Exasol equivalent and which are unnecessary in Exasol e.g.`USE/IGNORE INDEX`
10. In Exasol`SELECT`columns which are not part of the`GROUP-BY` must be enclosed in an aggregation of some sort (`COUNT, SUM, MAX, FIRST_VALUE, etc`) or will otherwise generate an error. MySQL randomly chooses a value if no aggregate function is specified.
	1. MySQL:`SELECT a FROM b GROUP BY c;`
	2. Exasol:`SELECT FIRST_VALUE(a) FROM b GROUP BY c; -- Note this generates an error in MySQL`
11. In Exasol, date/time interval arithmetic requires duration to be a string while in MySQL it can be a number.
	1. MySQL:`SELECT NOW() + INTERVAL 1 DAY`
	2. Exasol:`SELECT NOW() + INTERVAL '1' DAY`
12. In Exasol, date/time interval arithmetic requires the date to be explicitly cast as`DATE`if it's a string.
	1. MySQL:`SELECT '2001-02-03' + INTERVAL '1' DAY`
	2. Exasol:`SELECT DATE('2001-02-03') + INTERVAL '1' DAY`
13. In Exasol,`NULLs`in`ORDER-BY...ASC`are sorted last by default while in MySQL they are sorted first (and vice versa for`DESC`). You can specify`ORDER BY...ASC NULLS FIRST`in Exasol to mimic MySQL behavior.
14. MySQL does all string matching and sorting case-**in**sensitively while Exasol does it case-sensitively. To mimic the MySQL behavior in Exasol you can wrap all comparison terms in `UPPER() / LOWER()` (however note that this may cause performance degradation)
15. In string matching and sorting of VAR/CHAR values MySQL ignores all trailing spaces while Exasol does not. To mimic the MySQL behavior in Exasol you can wrap all string criteria/sorting terms in`RTRIM()` (may also cause performance degradation)
16. `''`is treated as`NULL`in Exasol . It doesn't distinguish between the two. So any MySQL behavior which treats`''`and`NULL`differently will behave differently in Exasol. There are many such behavior differences. Unfortunately it is not possible to make Exasol mimic MySQL in this regard. e.g.
	1. Comparisons:`'' = ''` is true and `'abc' = ''` is false in MySQL while both are `NULL` in Exasol
	2. Sorting: MySQL distinguishes between '' and `NULL` when sorting while Exasol does not
	3. Functions: There are many functions that will return `NULL` if any of the inputs are `NULL` and so in Exasol they will return `NULL` if passed in `''` while in MySQL they will not
17. In Exasol automatic datatype coercion is much stricter and so explicit casting is often necessary while it may not be necessary in MySQL.
18. In Exasol there is a much stricter need for`UNION`column datatypes to match across unions.
19. In Exasol`string + 0` doesn't convert a string into a number. Exasol optimizes away the`+ 0`. You need to use a`CAST(string AS INT)`or`string + 1 - 1`
20. Exasol does not support binary data columns so MySQL binary columns will need to be converted to char fields of some sort (or discarded)
21. Exasol dates support years up to 9999 while MySQL only supports up to 2155
22. In Exasol a correlated sub-select`SELECT`column must only return one row and it can't do that via `LIMIT 1` (as can be done in MySQL). Instead you have to use an single-group aggregate function (no`GROUP-BY`)
	1. MySQL:`SELECT (SELECT user_id FROM users WHERE roles.role_id = users.role_id LIMIT 1) FROM roles;`
	2. Exasol:`SELECT (SELECT FIRST_VALUE(user_id) FROM users WHERE roles.role_id = users.role_id) FROM roles;`
23. In Exasol a correlated sub-select`SELECT`column which is part of a`UNION`query where the column in other`UNIONs`is`NULL`will generate an error. At least one of the`NULLs`needs to be cast.
	1. MySQL:`SELECT (SELECT MAX(user_id) FROM users WHERE roles.role_id = users.role_id) FROM roles UNION SELECT NULL;`
	2. Exasol:`SELECT (SELECT MAX(user_id) FROM users WHERE roles.role_id = users.role_id) FROM roles UNION SELECT CAST(NULL AS INTEGER);`
24. In Exasol`JOIN...USING()` join syntax can be significantly slower than`JOIN...ON` when there are a large number of such joins. So in general use the `ON` syntax (Note that it is on Exasol's road-map to address this issue). In MySQL there is no performance difference between the two syntaxes.
25. In Exasol multiple`JOIN-USINGs`with the same column name generates a duplicate column error.
	1. MySQL:`SELECT * FROM a JOIN b USING(id) JOIN c USING(id);`
	2. Exasol:`SELECT * FROM a JOIN b ONa.id=b.idJOIN c ONa.id=c.id;`
26. In Exasol selecting a column referenced in a`USING()`cannot include the table name. In MySQL it can.
	1. MySQL:`SELECTa.idFROM a JOIN b USING(id)`
	2. Exasol:`SELECT id FROM a JOIN b USING(id)`
27. In MySQL`a JOIN b`with no`ON`clause is implicitly a cross join. In Exasol you have to explicitly say `a CROSS JOIN b`otherwise you get a syntax error.
28. In Exasol you can't have a sub-select inside of`ON`clause`JOIN`criteria. You have to rewrite the sub-query as a table and`JOIN`onto it.
	1. MySQL:`... JOIN a ON c1 = c2 AND c3 = (SELECT c4 ...)`
	2. Exasol:`... JOIN a ON c1 = c2 JOIN (SELECT c4 ...) AS t ON c3 = c4`
29. In Exasol, while `1/0`  are considered boolean in comparisons (e.g. `TRUE = 1` is TRUE) they are not considered boolean as operands of `AND/OR` . In MySQL they are.
	1. MySQL: `...WHERE 1`
	2. Exasol:`...WHERE 1 = TRUE` or `...WHERE CAST(1 AS BOOLEAN)`
30. In Exasol you cannot have a`HAVING`without a`GROUP BY`. In MySQL you can.
31. In Exasol criteria in a`WHERE/HAVING`clause cannot directly reference`SELECT`column aliases. The criteria needs to reference underlying column SQL or use`local.alias`
	1. MySQL:`SELECT t.col AS a FROM ... WHERE a = 1`
	2. Exasol:`SELECT t.col AS a FROM ... WHERE local.a = 1`
	3. or:`SELECT t.col AS a FROM ... WHERE t.col = 1`
32. The`ORDER-BY`in a `(...) UNION (...) ORDER BY ...` construct is a syntax error in Exasol (in MySQL it is not). It needs to be written as`SELECT * FROM (...) UNION (...) AS a ORDER BY ...`
33. MySQL's`ORDER-BY`sorts in this order: tab, empty-string, space whereas Exasol sorts: empty-string, tab, space
34. In Exasol date formatting can't include non-formatting alphanumeric characters. You have to CONCAT the formatted date with the non-formatting strings.
	1. MySQL:`DATE_FORMAT(NOW(),'%jth')`
	2. Exasol:`CONCAT(TO_CHAR(NOW(),'DDD'),'th')`
35. In`GROUP_CONCAT(DISTINCT a ORDER BY b)` Exasol collapses identical adjacent values of `a` *after* ordering by `b` while MySQL collapses all identical values of `a` regardless of the order.
36. `REGEXPs`in Exasol assume a leading`^`and trailing`$`while MySQL's don't. So you need an explicit`'.*'`in Exasol to emulate that.
	1. MySQL:`...REGEXP 'abc'`
	2. Exasol:`...REGXP_LIKE '.*abc.*'`
37. Exasol doesn't support`SQL_CALC_FOUND_ROWS + FOUND_ROWS()` construct. Instead you can just include a column which does`COUNT(*) OVER () AS num_rows`
38. Exasol doesn't support temporary tables like MySQL's. However tables (and all DDL) in Exasol are transactional (unlike in MySQL where they always auto-commit) so multiple sessions can simultaneously create the same table in their respective transactions as long as they rollback the transaction or drop the table before committing. Also consider using CTEs (via WITH clause) instead.
39. MySQL supports fractional time values out to microseconds whereas Exasol supports it out to milliseconds
40. MySQL automatically orders by GROUP-BY columns if an ORDER-BY is omitted while Exasol requires an explicit ORDER BY if you want it ordered.
41. When dividing by zero, MySQL returns NULL while Exasol generates an error
42. and more...

Of course the greatest lesson learned was that Exasol is *incredibly* fast at handling large datasets compared to MySQL! 

