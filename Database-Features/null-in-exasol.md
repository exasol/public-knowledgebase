# NULL in Exasol 
## Background

Generally speaking, NULL is not a special value, but it represents an undefined value. Given this, comparing anything against NULL is not applicable.  Therefore, any comparison of the form "column = NULL" always returns NULL in Exasol, even if that column contains NULL values. Especially joins do not generate matches on rows where the join condition contains NULL values. 

## Explanation

If a value is to be tested against NULL, the comparison operator has to be replaced by the [IS NULL](https://docs.exasol.com/sql_references/predicates/is_not_null.htm) and [IS NOT NULL](https://docs.exasol.com/sql_references/predicates/is_not_null.htm) predicates.

The following sample table will be used in all the examples on this page to demonstrate NULL handling.


```markup
CREATE OR REPLACE TABLE testnull
(
    num decimal(18, 0),
    boo BOOLEAN,
    dat date,
    str varchar(30)
);
 
INSERT INTO testnull VALUES
(1, false, '2010-02-03', 'first row'),
(NULL, true, '2010-02-04', 'second row'),
(3, NULL, '2010-02-05', 'third row'),
(4, true, NULL, 'fourth row'),
(5, false, '2010-02-07', NULL),
(6, true, '2010-02-08', '');
```

|NUM   |BOO   |DAT   |STR   |
|---|---|---|---|
|1   |false   |2010-02-03   |first row   |
|3   |   |2010-02-05   |third row   |
|4   |true   |   |fourth row   |
|5   |false  |2010-02-07   |   |
|6   |true   |2010-02-08   |   |
|   |true   |2010-02-04   |second row   |

### General Rules

The following basic rules apply to operations with NULL values:

* Comparison ('=', '<', ..) against a NULL value always returns NULL
* The predicates IS (NOT) NULL have to be used to check against NULL values
* Operations with NULL values return a NULL value.


```markup
SELECT
    num+1 num,
    case boo    when true then 'TRUE'
                when false then 'FALSE'
                else 'X'
    end AS boo,
    add_month(dat, 1) dat,
    case when str IS NULL then 'X' else str end str
FROM testnull;
```
will return the following results:

|NUM   |BOO   |DAT   |STR   |
|---|---|---|---|
|2   |false   |2010-03-03   |first row   |
|4   |X   |2010-03-05      |third row   |
|5   |true   |   |fourth row   |
|6   |false   |2010-03-07   |X   |
|7   |true |2010-03-08 |X |
|    |true |2010-03-04 |second row |

### NULL and Strings

Exasol does **not distinguish** between NULL and an empty string (''). The same basic rules apply to strings as they do to any other data type, with one exception:

Concatenation ('||', CONCAT) with a NULL value does not yield a NULL value, but the remaining operand(s). Only when all operands are NULL, the result also is NULL.


```"code-sql"
SELECT 'str: '||str A FROM testnull; 
```


| A |
| --- |
| str: second row |
| str: |
| str: third row |
| str: fourth row |
| str: first row |
| str: |

### Functions for handling NULL values

#### [NVL (expr1, expr2)](https://docs.exasol.com/sql_references/functions/alphabeticallistfunctions/nvl.htm)

When 'expr1' is NULL, 'expr2' is returned, else 'expr1'. NVL stands for 'Null Value'.

The equivalent CASE-expression is: CASE WHEN expr1 IS NULL THEN expr2 ELSE expr1 END

#### [COALESCE (expr1, expr2, ...)](https://docs.exasol.com/sql_references/functions/alphabeticallistfunctions/coalesce.htm)

Returns the first value of the parameter list that is not NULL. When all arguments are NULL, NULL is returned.

The equivalent CASE-expression is: CASE WHEN expr1 IS NOT NULL THEN expr1 WHEN expr2 IS NOT NULL THEN expr 2 ... ELSE NULL END

#### [ZEROIFNULL(number)](https://docs.exasol.com/sql_references/functions/alphabeticallistfunctions/zeroifnull.htm)

Returns the integer 0 when number is NULL. Otherwise, number itself is returned.

The equivalent CASE-expression is:


```markup
CASE WHEN number is NULL THEN 0 ELSE number END
```
#### [NULLIFZERO(number)](https://docs.exasol.com/sql_references/functions/alphabeticallistfunctions/nullifzero.htm)

Returns NULL when number has the value 0. Otherwise, number is returned. This function is useful to prevent division by zero errors (see example).

The equivalent CASE-expression is:


```markup
CASE WHEN number=0 THEN NULL 
ELSE number END
```
#### [DECODE(expr, val1, ret1, ..., default)](https://docs.exasol.com/sql_references/functions/alphabeticallistfunctions/decode.htm)

This function is not primarily designed for NULL handling, it will return the first retX value for which expr=valX holds true. However, the function is exceptional in the sense that it will match NULL values when asked to do so.

The equivalent CASE-expression would have to fall back on the corresponding NULL-Predicate:


```markup
CASE WHEN expr=val1 THEN ret1 WHEN expr is NULL then ... ELSE default END
```
If no comparison against NULL is required, the following expression also is equivalent:


```markup
CASE expr WHEN val1 THEN ret1 WHEN val2 THEN ... ELSE default END
```
Now we can make some different comparisons to our table:


```markup
SELECT
    num,
    zeroifnull(num) + 1 num1,
    nvl(cast(boo AS varchar(10)), 'unknown'),
    coalesce(str, 'X') str,
    1/nullifzero(num-3) num2
FROM testnull;
```

| NUM | NUM1 | NVL | STR | NUM2 |
|---|---|---|---|---|
|   |1   |true   |second row   |   |
|5   |6   |false   |X   |0.5   |
|3   |4   |unknown   |third row   |   |
|4   |5   |true   |fourth row   |1   |
|1   |2   |false   |first row   |-0.5   |
|6  |7   |true   |X   |0.33333   |

#### Count the number of NULL-Values


```"code-sql"
SELECT count(*)-count(col) AS NULLCOUNT FROM tab;
```
## Additional References

* [IS NULL Predicate](https://docs.exasol.com/sql_references/predicates/is_not_null.htm)
* [Exasol Functions](https://docs.exasol.com/sql_references/functions/all_functions.htm)
* [Data Types](https://docs.exasol.com/sql_references/data_types/datatypesoverview.htm)
* [NULL in UDF's and Lua Scripts](https://exasol.my.site.com/s/article/NULL-in-UDFs-and-Lua-Scripts)
