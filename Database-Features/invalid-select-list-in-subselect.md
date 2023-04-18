# Invalid Select-list in Subselect

## Question
I'm using Exasol 7.0.7 on Windows with Docker.

The following query doesn't work, although I don't see any reason why it shouldn't

> SELECT (SELECT a)  
FROM VALUES (1) AS a(a);

I'm getting this error: 

> SQL Error [42000]: invalid select-list in subselect [line 1, column 17]

## Answer
This feature is not supported by Exasol.
Exasol supports references to columns of outer tables only at a few places.

Exasol transforms the query from above into:

> SELECT (SELECT a FROM DUAL) FROM VALUES (1) AS a(a);

As there is no column 'a' in DUAL, you get the error message from above.

In general, references to columns of outer tables are not supported in the select list.
References in WHERE conditions (with some restrictions) work:

> CREATE TABLE T1(c1 INT);  
INSERT INTO T1 VALUES(1);  
INSERT INTO T1 VALUES(4);  
SELECT (SELECT c1 FROM T1 WHERE T1.c1=T2.c2) FROM VALUES(1) AS T2(c2); 