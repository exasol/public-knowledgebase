# "datetime field underflow" Error When Using ADD_DAYS with Minimum DATE Value

## Problem

While executing a self-join on the TEST table to find pairs of rows where DATEVALUE differs exactly by three days, the following error occurs:

```text
[Code: 0, SQL State: 22104]  data exception - datetime field underflow
```

### Steps to reproduce

#### Create and insert into the table

```sql
CREATE OR REPLACE TABLE test(DATEVALUE DATE);

INSERT INTO test (DATEVALUE) VALUES (date '0001-01-01');
INSERT INTO test (DATEVALUE) VALUES (date '2025-09-01');
INSERT INTO test (DATEVALUE) VALUES (date '2025-09-04');
INSERT INTO test (DATEVALUE) VALUES (date '9999-12-31');
```

#### Execute the query

```sql
SELECT 
    *
FROM 
    TEST t1
JOIN 
    TEST t2 
ON
    ADD_DAYS(t1.DATEVALUE, -3) = t2.DATEVALUE;
```

#### Recommendation

Please provide guidance or a workaround for handling this scenario in Exasol, such as ignoring values that might result in an underflow, or alternative ways to compare date differences without triggering this error.

## Explanation

The error occurs when trying to subtract 3 days from the minimum DATE value (‘0001-01-01’). This operation produces a result below the lower limit for the DATE data type, leading to a “datetime field underflow” error.

A datetime field underflow in SQL indicates that the system is attempting to store a date or time value earlier than the minimum value allowed by the data type. This typically happens when calculations or data insertions yield values that are outside the range the field can accept.

In Exasol, the smallest valid DATE value is ‘0001-01-01’ (January 1st, year 1). This aligns with the SQL standard for DATE types. Both the DATE and TIMESTAMP types in Exasol support a range from this minimum date up to December 31, 9999.

## Solution

### Solution Idea

Let us try with the following statement

```sql
FROM 
    TEST t1
JOIN 
    TEST t2 
ON
    t2.DATEVALUE = ADD_DAYS(t1.DATEVALUE, -3)
WHERE
    DAYS_BETWEEN(t1.DATEVALUE, '0001-01-01') > 3;
```

#### Explanation of the idea

This WHERE clause should act as a safeguard. It should filter out any rows from t1 that would cause an underflow error when calculating ADD_DAYS(t1.DATEVALUE, -3). Specifically, it should check if the t1.DATEVALUE is more than three days after the minimum supported date ('0001-01-01'). This should prevent the database from trying to calculate a date before the year 1.

#### The Problem with this Approach

We are getting the datetime field underflow error again because the database is still attempting to perform the ADD_DAYS(t1.DATEVALUE, -3) calculation on a row where the resulting date is too small, even though you have a WHERE clause.

The issue lies in the order of operations and the specific behavior of the Exasol query optimizer.

While you've logically placed a WHERE clause to filter out problematic rows, the database's query optimizer might not execute the operations in that exact order. The optimizer's job is to find the most efficient way to run a query, and it may choose to perform the JOIN calculation (ADD_DAYS) before it applies the WHERE filter.

The ON clause is part of the JOIN operation. In some cases, the database evaluates the entire ON condition for every possible combination of rows from t1 and t2 before it even considers the WHERE clause. If a row in t1 has a DATEVALUE of '0001-01-02', the ADD_DAYS function will be called on it, resulting in a date of '0000-12-30', which is an underflow.

The WHERE clause is designed to filter the results of the join, but it doesn't always prevent the functions within the join from being executed.

### Final Solution

The most robust way to prevent this error is to use a CASE statement inside the ON clause, similar to the above query. The CASE statement creates a conditional logic that is part of the JOIN itself, ensuring the ADD_DAYS function is only executed when the condition is met.

```sql
SELECT
    *
FROM
    TEST t1
JOIN
    TEST t2
ON
    t2.DATEVALUE = (
        CASE 
            WHEN DAYS_BETWEEN(t1.DATEVALUE, '0001-01-01') > 3 
            THEN ADD_DAYS(t1.DATEVALUE, -3)
            ELSE NULL 
        END
    );
```

By placing the CASE statement directly in the ON clause, you are telling the database: "Only perform this ADD_DAYS calculation if the date is valid; otherwise, use NULL for the join key." A NULL value will never match t2.DATEVALUE, so it effectively filters out the problematic rows without causing the underflow error.

## References

* [Documentation of Date and time data types](https://docs.exasol.com/db/latest/sql_references/data_types/datatypedetails.htm#Dateandtimedatatypes)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
