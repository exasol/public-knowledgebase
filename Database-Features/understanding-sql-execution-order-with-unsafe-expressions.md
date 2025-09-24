# Understanding SQL Execution Order Pitfalls with Unsafe Expressions

## Problem

When working with SQL, it’s easy to assume that filters in a CTE or subquery are always applied before their joins or filters expressions are evaluated.
However, because SQL is **declarative**, the database optimizer decides the actual execution plan. This can lead to unexpected errors when using unsafe expressions like:

- Division — risk of divide-by-zero errors.
- Date/Time Shift Functions (ADD_MINUTES, ADD_HOURS, ADD_DAYS, ADD_MONTHS, ADD_YEARS, etc.) — may fail with invalid ranges (e.g., leap years, month overflows).
- Casting and Conversion Functions (TO_DATE, TO_TIMESTAMP, or other type casts) — errors possible when input format doesn’t match the expected pattern.
- String-to-number conversions — errors with invalid characters.
- Null handling in expressions — may cause unexpected failures if operands are NULL.
- Aggregations or math functions (e.g., SQRT, LOG, LN) — errors with invalid arguments (e.g., square root of negative number, logarithm of non-positive number).
- etc.

## Example

The following example demonstrates the issue:

```sql
open schema vit;

create or replace table test (DATEVALUE date);

insert into test (DATEVALUE) values (date'0001-01-01');
insert into test (DATEVALUE) values (date'2025-09-01');
insert into test (DATEVALUE) values (date'2025-09-04');


WITH FILTERED_SIMPLE_DATE as (
    SELECT *
    FROM test d
    WHERE DATEVALUE between '2025-01-02' AND '2025-10-01' 
)
        SELECT * 
        FROM FILTERED_SIMPLE_DATE t
        INNER JOIN FILTERED_SIMPLE_DATE d on ADD_DAYS(d.DATEVALUE, -3) = t.DATEVALUE;

-- [Code: 0, SQL State: 22104]  data exception - datetime field underflow (Session: 1843518053339627520)
```

Here, the error arises because ADD_DAYS(d.DATEVALUE, 1 - TO_CHAR(d.DATEVALUE, 'D')) tries to process the value '0001-01-01', even though the CTE filter should have excluded it. Depending on the optimizer’s decision, the filter may not be applied before the join expression is evaluated, leading to inconsistent behavior across database versions, different filter conditions etc.

## Solution

- Always keep in mind that SQL does not guarantee execution order: filters, joins, and expression evaluations may occur in different sequences depending on the execution plan.
- Avoid unsafe expressions: handle edge cases like invalid or extreme values explicitly (e.g. use safe functions like TRUNC(d.DATEVALUE, 'W') instead of ADD_DATES to calculate the start of the week).
- Enforce execution order when needed: if you want to guarantee the filter is applied before the join, you can force materialization of the CTE (e.g. add ORDER BY FALSE at the end of the CTE). **Keep in mind** that large materializations can consume a significant amount of temporary data, which may lead to block swapping and reduced throughput.
- Alternatively, you can use a secure approach like CASE-WHEN to explicitly handle unsafe input values.

```sql
open schema vit;

create or replace table test (DATEVALUE date);

insert into test (DATEVALUE) values (date'0001-01-01');
insert into test (DATEVALUE) values (date'2025-09-01');
insert into test (DATEVALUE) values (date'2025-09-04');

-- 1. Materialization
WITH FILTERED_SIMPLE_DATE as (
    SELECT *
    FROM test d
    WHERE DATEVALUE between '2025-01-02' AND '2025-10-01'
    ORDER BY false
)
        SELECT * 
        FROM FILTERED_SIMPLE_DATE t
        INNER JOIN FILTERED_SIMPLE_DATE d on ADD_DAYS(d.DATEVALUE, -3) = t.DATEVALUE;

-- Success

-- 2. CASE_WHEN
WITH FILTERED_SIMPLE_DATE as (
    SELECT *
    FROM test d
    WHERE DATEVALUE between '2025-01-02' AND '2025-10-01'
)
        SELECT * 
        FROM FILTERED_SIMPLE_DATE t
        INNER JOIN FILTERED_SIMPLE_DATE d on case when d.DATEVALUE > date'1900-01-01' then ADD_DAYS(d.DATEVALUE, -3) else null end = t.DATEVALUE;

-- Success
```

## Additional References

- [Enforcing materializations with ORDER BY FALSE in subselects, views or CTEs](/Database-Features/enforcing-materializations-with-order-by-false-in-subselects.md)
- [Documentation of CASE](https://docs.exasol.com/db/latest/sql_references/functions/alphabeticallistfunctions/case.htm)
- ["datetime field underflow" Error When Using ADD_DAYS with Minimum DATE Value](/Database-Features/datetime-field-underflow-error-when-using-add-days-with-minimum-date-value.md)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
