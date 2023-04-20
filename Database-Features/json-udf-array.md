# JSON UDF Example
An extended version for the following question I was asked recently:

From something like this: 

|Column1 |Column2|
|-|-|
|A,B,C|Hello|


Into this:
|Column1 |Column2|
|-|-|
|A|Hello|
|B|Hello|
|C|Hello|
 

Following changes to my original post:

1. We are dealing with strings here, to make it a json compatible array, every string has to be quoted, that is why you have to add the "replace" sql function.
2. There is an additional column, which is replicated automatically, and for this column there is no need to process it through the JSON_EXTRACT function (col2).
```
-- this is your test "table", have a look at it
values(('A,B,C'),'Hello'),(('D,E,F'),'Bye') as t(col1,col2);
 
-- some sql and json magic
with tmp as(
        values(('A,B,C'),'Hello'),(('D,E,F'),'Bye') as t(col1,col2)
)
SELECT 
    JSON_EXTRACT( 
        '["'||replace(col1,',','","')||'"]'
        ,
        '$#'
        )
        EMITS(col1 varchar (1)),col2 from tmp;
```

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 