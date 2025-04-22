# What is "Union all join inversion"?

<!-- meta
   LAST_VERIFIED: Exasol 8.34.0
-->

## Introduction

The content of this article provides more information on [Changelog-content-22913](https://exasol.my.site.com/s/article/Changelog-content-7802) and applies to Exasol versions starting with **8.34.0**.

There is another, older, automated optimization[^union-all-opt] for `UNION ALL` covering the case of identical tables in every branch.

[^union-all-opt]: Union All Optimization: [Knowledge Base Article](https://exasol.my.site.com/s/article/Union-all-optimization)

## Question

What does "union all join inversion" do, how can I use it and why would I want to?

## Answer: How

This is the simplest part: This is fully automated, you do not have to change any system settings or queries -- unless your setup exceeds one of the *Limitations* shown below.

## Answer: Why

Table operators (`UNION`, `MINUS`, `INTERSECT`) are powerful tools, but in Exasol they come with some drawbacks:

Those operations act as *materialization barriers*: At query execution time, the result of the operation is always fully materialized in a temporary table (tmp_subselect, see profile examples below) before the remainder of the query can be processed.

Exasol versions prior to 8.34.0 already do their best to reduce the footprint of the operation by removing unused columns ("select list elimination") and pushing applicable filters into each of the operands ("filter propagation").

**However**, one frequently used type of filter is *not applicable* to filter propagation: a "filter join" as shown in the following example:

```sql
WITH sales_and_returns AS (
    -- typically, this is not part of the query, but hidden
    -- in some view providing a unified data source
    SELECT ss_sold_date_sk, ss_store_sk, ss_net_profit
        FROM store_sales
    UNION ALL
    SELECT sr_returned_date_sk, sr_store_sk, -sr_net_loss
        FROM store_returns
)
SELECT d_date, ss_store_sk, SUM(ss_net_profit) AS profit
FROM sales_and_returns
-- join with dimension table 
JOIN date_dim
  ON d_date_sk = ss_sold_date_sk
-- filter on dimension table
WHERE d_year = 2003 AND d_moy = 6
GROUP BY d_date, ss_store_sk
```

**Note:** All queries in this article use the **TPC-DS**[^tpc-ds] data structures.

The query above used to look like this in profiling[^profiling] (shortened table):

|PART_ID|PART_NAME|OBJECT_NAME|OBJECT_ROWS|OUT_ROWS|
|---:|---|---|---:|---:|
|2|SCAN|STORE_SALES|28,800,991|28,800,991|
|3|INSERT|tmp_subselect0|0|28,800,991|
|4|SCAN|STORE_RETURNS|2,875,432|2,875,432|
|5|INSERT|tmp_subselect0|28,800,991|2,875,432|
|6|COLUMN STATISTICS|tmp_subselect0|31,676,423|(null)|
|7|SCAN|tmp_subselect0|31,676,423|31,676,423|
|8|JOIN|DATE_DIM|438,294|8,570|

Here, the pipelines of parts (2-3) and (4-5) create the materialized union of about 32 million rows, without any filter applied.
Only the join with `date_dim` in part 8 can apply the provided filter.

**Note:** This example uses a simple table for demonstration purposes. See point 4 in *Limitations* below for the full set of supported filter-joins.

[^tpc-ds]: Official site: [https://www.tpc.org/tpcds/](https://www.tpc.org/tpcds/)
[^profiling]: Profiling Documentation: [https://docs.exasol.com/db/latest/database_concepts/profiling.htm](https://docs.exasol.com/db/latest/database_concepts/profiling.htm "Docs: Profiling")

## Answer: What

On a mathematics level, the optimization is pretty simple to describe:

```math
(A+B) * C == A*C + B*C
```

because neither `UNION ALL` ('+') nor `JOIN` ('*') need to care about duplicates on either side.

Similar to the regular filter propagation, the new optimization will "push" the filtering join into each of the union all branches, thereby *inverting* the order of operations:

```sql
WITH sales_and_returns AS (
    -- joins added automatically by the Exasol optimizer
    SELECT d_date, ss_store_sk, ss_net_profit
      FROM store_sales
      JOIN date_dim
        ON d_date_sk = ss_sold_date_sk
     WHERE d_year = 2003 AND d_moy = 6

    UNION ALL
    
    SELECT d_date, sr_store_sk, -sr_net_loss
      FROM store_returns
      JOIN date_dim
        ON d_date_sk = sr_returned_date_sk
     WHERE d_year = 2003 AND d_moy = 6
)
SELECT d_date, ss_store_sk, SUM(ss_net_profit) AS profit
-- materialized union-all (8500 rows)
FROM sales_and_returns
GROUP BY d_date, ss_store_sk;
```

The accompanying execution profile would look like that:

|PART_ID|PART_NAME|OBJECT_NAME|OBJECT_ROWS|OUT_ROWS|
|---:|---|---|---:|---:|
|2|SCAN|DATE_DIM|438,294|180[^replicated]|
|3|JOIN|STORE_SALES|28,800,991|0|
|4|INSERT|tmp_subselect0|0|0|
|5|SCAN|DATE_DIM|438,294|180|
|6|JOIN|STORE_RETURNS|2,875,432|8,570|
|7|INSERT|tmp_subselect0|0|8,570|

[^replicated]: Note that profiling reports 180 matching rows for our "one month" filter. The reason for this is is that `date_dim` is treated as a *replicated table* in this use case, returning 30 rows on each of the 6 nodes of the showcase system.

This optimized execution provides multiple advantages:

- The date filter is applied before materialization, potentially **saving a lot of TEMP RAM**.
- The date join is now applied on individual tables instead of on the big `tmp_subselect`. Indices on tables are persistent, while **indices on temporary objects** die with the object and potentially have to be re-created again within every query.
- Better insights... checking the profile above, we immediately see that the large `store_sales` table does not actually provide any rows matching the date filter.

**Note:** This optimization is *repeatable*, which means

1. it can push joins into cascaded `UNION ALL` subselects
1. it can push multiple joins into one `UNION ALL`

## Limitations

The optimization described above is part of Exasol's rule-based *structural optimizer*. While very powerful, this optimizer part does not have access to actual table objects and their statistical information (sizes, selectivity, uniqueness, ...). For this reason, certain limitations were added to prevent the improvement from backfiring: Each join we push into the union all contains the risk of actually increasing the number of rows and/or columns that need to be materialized.

### 1: Four Or Less Union Branches

As copying parts of the query graph for duplication will make the overall graph more complex and prone to *increased compile time*, the optimizer refuses to push joins into unions with more than 4 branches.

### 2: Only UNION ALL

The other table operators `UNION`, `MINUS` and `INTERSECT` have to check full rows for identity / uniqueness, so adding columns from another table would likely break their semantic.

Therefore, the union-join-inversion can only be applied to `UNION ALL`.

### 3: Only INNER JOINS

Only inner joins are applicable to be pushed into a `UNION ALL`.

Examples explaining the limitation, using the same `sales_and_returns` view:

```sql
SELECT d_date, ss_store_sk, SUM(ss_net_profit) AS profit
FROM sales_and_returns
LEFT JOIN date_dim
  ON d_date_sk = ss_sold_date_sk
  AND d_year = 2003 AND d_moy = 6
```

The left join by definition will not *filter* any rows from the union all. Thereby, pushing it into the union all will only increase the risk of increasing its size, by either adding too many new columns or by duplicating rows with multiple join hits.

<!--
== TEST QUERY 1 ==
WITH sales_and_returns AS (
    -- typically, this is not part of the query, but hidden
    -- in some view providing a unified data source
    SELECT ss_sold_date_sk, ss_store_sk, ss_net_profit
        FROM store_sales
    UNION ALL
    SELECT sr_returned_date_sk, sr_store_sk, -sr_net_loss
        FROM store_returns
)
SELECT d_date, ss_store_sk, SUM(ss_net_profit) AS profit
FROM sales_and_returns
LEFT JOIN date_dim
  ON d_date_sk = ss_sold_date_sk
  -- WHERE would convert this into an inner join!
  AND d_year = 2003 AND d_moy = 6
GROUP BY d_date, ss_store_sk

== EXPECT: No union-join-inversion
-->

---

```sql
SELECT d_date, ss_store_sk, SUM(ss_net_profit) AS profit
FROM date_dim
LEFT JOIN sales_and_returns
  ON d_date_sk = ss_sold_date_sk
WHERE d_year = 2003 AND d_moy = 6
```

The left join here will need an explicit "hit or no hit" answer for every row of `date_dim`, to generate the *null match* if necessary. This decision can not be simply applied twice in two different join pipelines.

<!--
== TEST QUERY 2 ==
WITH sales_and_returns AS (
    -- typically, this is not part of the query, but hidden
    -- in some view providing a unified data source
    SELECT ss_sold_date_sk, ss_store_sk, ss_net_profit
        FROM store_sales
    UNION ALL
    SELECT sr_returned_date_sk, sr_store_sk, -sr_net_loss
        FROM store_returns
)
SELECT d_date, ss_store_sk, SUM(ss_net_profit) AS profit
FROM date_dim
LEFT JOIN sales_and_returns
  ON d_date_sk = ss_sold_date_sk
WHERE d_year = 2003 AND d_moy = 6
GROUP BY d_date, ss_store_sk

== EXPECT: No union-join-inversion
-->

### 4: Query Indicates Filtering

As explained above, this optimization does not have access to table statistics and can thereby not estimate effectiveness of a join: The query itself **must contain elements** that indicate a filtering join.

**Supported Predicates:**

- `<column> = <constant>`: Equality condition between a constant value and an unmodified column. A constant may be a simple SQL literal or a more complex expression like `ADD_DAYS(SYSDATE, -5)`; but it must be computable without any data processing, so even scalar non-correlated subselects do not count as constants.
- `<column> BETWEEN <constant> AND <constant>` -- note that usually, `A >= X AND A <= Y` is automatically converted into the equivalent `BETWEEN` expression.

**Note:** Only *strong* predicates are accepted; any predicate that is weakened by an `OR` clause is not supported.

**Unsupported Predicates:**

**Anything else**. 'Unsupported' in this case means that its presence does not count as filtering, but it will also not prevent the optimization based on another predicate.

Worth mentioning:

- inequality conditions: `ship_date >= DATE '2025-02-01'` or `delivery_state != 'DELIVERED'`
- expressions on columns: `TO_DATE(col) = DATE '2025-02-01'`
- multi-column conditions: `t.ship_date = t.sales_date`
- subselects: `ship_date = (SELECT MAX(ship_date) FROM lookup_table)`
- IN lists: `ship_date IN (DATE '2025-02-01', DATE '2025-02-02')`

For different kinds of "joined tables", the optimizer looks for the supported predicates in different places:

#### 4.1. Simple Table

For simple tables as shown in the initial example, the predicates must be part of the join condition or in the `WHERE` clause of the query:

**Supported Cases:**

```sql
-- filter in join clause
FROM sales_and_returns
JOIN date_dim
  ON d_date_sk = ss_sold_date_sk
 AND d_year = 2003 AND d_moy = 6
```

<!--
== TEST QUERY 3 ==
WITH sales_and_returns AS (
    -- typically, this is not part of the query, but hidden
    -- in some view providing a unified data source
    SELECT ss_sold_date_sk, ss_store_sk, ss_net_profit
        FROM store_sales
    UNION ALL
    SELECT sr_returned_date_sk, sr_store_sk, -sr_net_loss
        FROM store_returns
)
SELECT d_date, ss_store_sk, SUM(ss_net_profit) AS profit
FROM sales_and_returns
JOIN date_dim
  ON d_date_sk = ss_sold_date_sk
  AND d_year = 2003 AND d_moy = 6
GROUP BY d_date, ss_store_sk

== EXPECT: inversion
-->

```sql
-- filter in where clause
FROM sales_and_returns
JOIN date_dim
  ON d_date_sk = ss_sold_date_sk
...
WHERE d_year = 2003 AND d_moy = 6
```

<!--
== TEST QUERY 4 ==
WITH sales_and_returns AS (
    -- typically, this is not part of the query, but hidden
    -- in some view providing a unified data source
    SELECT ss_sold_date_sk, ss_store_sk, ss_net_profit
        FROM store_sales
    UNION ALL
    SELECT sr_returned_date_sk, sr_store_sk, -sr_net_loss
        FROM store_returns
)
SELECT d_date, ss_store_sk, SUM(ss_net_profit) AS profit
FROM sales_and_returns
JOIN date_dim
  ON d_date_sk = ss_sold_date_sk
WHERE d_year = 2003 AND d_moy = 6
GROUP BY d_date, ss_store_sk

== EXPECT: inversion
-->

**Note:** Due to the already mentioned *filter propagation*, appropriate filters on a higher subquery level or in `HAVING` clauses are *likely* to be pushed to the right place before the union-all-join-inversion is evaluated.

**Unsupported Cases:**

```sql
-- no (visible) filter at all
FROM sales_and_returns
JOIN date_dim
  ON d_date_sk = ss_sold_date_sk
```

<!--
== TEST QUERY 5 ==
WITH sales_and_returns AS (
    -- typically, this is not part of the query, but hidden
    -- in some view providing a unified data source
    SELECT ss_sold_date_sk, ss_store_sk, ss_net_profit
        FROM store_sales
    UNION ALL
    SELECT sr_returned_date_sk, sr_store_sk, -sr_net_loss
        FROM store_returns
)
SELECT d_date, ss_store_sk, SUM(ss_net_profit) AS profit
FROM sales_and_returns
JOIN date_dim
  ON d_date_sk = ss_sold_date_sk
GROUP BY d_date, ss_store_sk

== EXPECT: no inversion
-->

```sql
-- unsupported predicate type
FROM sales_and_returns
JOIN date_dim
  ON d_date_sk = ss_sold_date_sk
 AND d_year >= 2003
```

<!--
== TEST QUERY 6 ==
WITH sales_and_returns AS (
    -- typically, this is not part of the query, but hidden
    -- in some view providing a unified data source
    SELECT ss_sold_date_sk, ss_store_sk, ss_net_profit
        FROM store_sales
    UNION ALL
    SELECT sr_returned_date_sk, sr_store_sk, -sr_net_loss
        FROM store_returns
)
SELECT d_date, ss_store_sk, SUM(ss_net_profit) AS profit
FROM sales_and_returns
JOIN date_dim
  ON d_date_sk = ss_sold_date_sk
  AND d_year >= 2003
GROUP BY d_date, ss_store_sk

== EXPECT: no inversion
-->

```sql
-- predicate weakened by OR
FROM sales_and_returns
JOIN date_dim
  ON d_date_sk = ss_sold_date_sk
 AND (d_year = 2003 OR d_year = 2004)
```

<!--
== TEST QUERY 7 ==
WITH sales_and_returns AS (
    -- typically, this is not part of the query, but hidden
    -- in some view providing a unified data source
    SELECT ss_sold_date_sk, ss_store_sk, ss_net_profit
        FROM store_sales
    UNION ALL
    SELECT sr_returned_date_sk, sr_store_sk, -sr_net_loss
        FROM store_returns
)
SELECT d_date, ss_store_sk, SUM(ss_net_profit) AS profit
FROM sales_and_returns
JOIN date_dim
  ON d_date_sk = ss_sold_date_sk
  AND (d_year = 2003 OR d_year = 2004)
GROUP BY d_date, ss_store_sk

== EXPECT: no inversion
-->

#### 4.2. Materialized Subselect

At this stage of optimization, a "materialized subselect" is usually a **view** or **CTE**[^cte] that was automatically pre-materialized due to being **used multiple times** in the query.

Unfortunately, information used to materialize the subselect is lost in the process, so the subselect has to be treated as a *simple table* as shown in 4.1 above.

[^cte]: Common Table Expression; see `WITH` clause at [https://docs.exasol.com/db/latest/sql/select.htm](https://docs.exasol.com/db/latest/sql/select.htm "Docs: SELECT")

#### 4.3. Single-Table Subselect

This category contains all other subselects, regardless of their complexity or structure; the only condition here is that the `FROM` clause in the subselect must itself only contain one simple or materialized table.

In other words: The subselect must not contain any joins.

**Note:** Even the "standard solution" of `ORDER BY FALSE` will not make a subselect 'materialized' in this stage of the optimization!

In case of a subselect, the search for an applicable filter predicate is performed in the `WHERE` clause of that subselect.

**Supported Cases:**

```sql
-- filter present in subselect
FROM sales_and_returns
JOIN (SELECT * FROM date_dim WHERE d_year = 2003)
  ON d_date_sk = ss_sold_date_sk
```

<!--
== TEST QUERY 8 ==
WITH sales_and_returns AS (
    -- typically, this is not part of the query, but hidden
    -- in some view providing a unified data source
    SELECT ss_sold_date_sk, ss_store_sk, ss_net_profit
        FROM store_sales
    UNION ALL
    SELECT sr_returned_date_sk, sr_store_sk, -sr_net_loss
        FROM store_returns
)
SELECT d_date, ss_store_sk, SUM(ss_net_profit) AS profit
FROM sales_and_returns
JOIN (SELECT * FROM date_dim WHERE d_year = 2003)
  ON d_date_sk = ss_sold_date_sk
GROUP BY d_date, ss_store_sk

== EXPECT: inversion
-->

```sql
FROM sales_and_returns
-- local filter not applicable: wrong type
JOIN (SELECT * FROM date_dim WHERE d_year >= 2003)
  ON d_date_sk = ss_sold_date_sk
...
GROUP BY ..., d_year, ...
-- filter propagated: HAVING -> WHERE -> JOIN -> SUBSELECT
HAVING d_year = 2004
```

<!--
== TEST QUERY 9 ==
WITH sales_and_returns AS (
    -- typically, this is not part of the query, but hidden
    -- in some view providing a unified data source
    SELECT ss_sold_date_sk, ss_store_sk, ss_net_profit
        FROM store_sales
    UNION ALL
    SELECT sr_returned_date_sk, sr_store_sk, -sr_net_loss
        FROM store_returns
)
SELECT d_year, ss_store_sk, SUM(ss_net_profit) AS profit
FROM sales_and_returns
JOIN (SELECT * FROM date_dim WHERE d_year >= 2003)
  ON d_date_sk = ss_sold_date_sk
GROUP BY d_year, ss_store_sk
HAVING d_year = 2004

== EXPECT: inversion
-->

```sql
FROM sales_and_returns
JOIN (
  -- get last day of every month
  SELECT d_moy, MAX(d_date_sk) as d_date_sk
  FROM date_dim
  WHERE d_year = 2003
  GROUP BY d_moy
)
  ON d_date_sk = ss_sold_date_sk
```

<!--
== TEST QUERY 10 ==
WITH sales_and_returns AS (
    -- typically, this is not part of the query, but hidden
    -- in some view providing a unified data source
    SELECT ss_sold_date_sk, ss_store_sk, ss_net_profit
        FROM store_sales
    UNION ALL
    SELECT sr_returned_date_sk, sr_store_sk, -sr_net_loss
        FROM store_returns
)
SELECT d_moy, ss_store_sk, SUM(ss_net_profit) AS profit
FROM sales_and_returns
JOIN (
  -- get last day of every month
  SELECT d_moy, MAX(d_date_sk) as d_date_sk
  FROM date_dim
  WHERE d_year = 2003
  GROUP BY d_moy
)
  ON d_date_sk = ss_sold_date_sk
GROUP BY d_moy, ss_store_sk

== EXPECT: inversion
-->

**Notes:**

- As usual, compatible filters specified on a higher query level may be propagated into the subselect, possibly making it eligible for the union-join-inversion.
- Also, very simple subselects might be subject to *subquery elimination*, embedding their table or join graph into the parent graph. After that, case 4.1 might be applicable.

---

**Unsupported Cases:**

```sql
FROM sales_and_returns
JOIN (
    -- subselect contains more than one table
    SELECT DISTINCT d_date_sk
    FROM date_dim
    JOIN promotion
      ON d_date_sk between p_start_date_sk and p_end_date_sk
    -- applicable filter predicate
    where P_PROMO_ID = 'AAAAAAAAPAAAAAAA'
)
  ON d_date_sk = ss_sold_date_sk
```

<!--
== TEST QUERY 10 ==
WITH sales_and_returns AS (
    -- typically, this is not part of the query, but hidden
    -- in some view providing a unified data source
    SELECT ss_sold_date_sk, ss_store_sk, ss_net_profit
        FROM store_sales
    UNION ALL
    SELECT sr_returned_date_sk, sr_store_sk, -sr_net_loss
        FROM store_returns
)
select count(*)
FROM sales_and_returns
JOIN (
    -- subselect contains more than one table
    SELECT DISTINCT d_date_sk
    FROM date_dim
    JOIN promotion
      ON d_date_sk between p_start_date_sk and p_end_date_sk
    -- applicable filter predicate
    where P_PROMO_ID = 'AAAAAAAAPAAAAAAA'
)
  ON d_date_sk = ss_sold_date_sk

== EXPECT: no inversion
-->

### 5: One-Way Strict Join

A table join is applicable for this push-down only if the join condition is exclusively between this table and the union all, and it joins two columns without expressions.

**Supported Cases:**

Assuming there is a `WHERE` condition filtering on `date_dim`...

```sql
FROM sales_and_returns
JOIN date_dim
    -- strict column-to-column predicate
  ON d_date_sk = ss_sold_date_sk
  -- does not block other predicates
  AND d_dom < 15
```

<!--
== TEST QUERY 11 ==
WITH sales_and_returns AS (
    -- typically, this is not part of the query, but hidden
    -- in some view providing a unified data source
    SELECT ss_sold_date_sk, ss_store_sk, ss_net_profit
        FROM store_sales
    UNION ALL
    SELECT sr_returned_date_sk, sr_store_sk, -sr_net_loss
        FROM store_returns
)
select count(*)
FROM sales_and_returns
JOIN date_dim
    -- strict column-to-column predicate
  ON d_date_sk = ss_sold_date_sk
  -- does not block other predicates
  AND d_dom < 15
WHERE d_year = 2003

== EXPECT: inversion
-->

```sql
FROM sales_and_returns
JOIN date_dim
  ON d_date_sk = ss_sold_date_sk
-- note: this join is "bad", but serves as demonstration case
JOIN inventory
  ON inv_item_sk = ss_item_sk
  -- join condition not part of the sales/date join
  AND d_date_sk = ss_date_sk
```

<!--
== TEST QUERY 12 ==
WITH sales_and_returns AS (
    -- typically, this is not part of the query, but hidden
    -- in some view providing a unified data source
    SELECT ss_sold_date_sk, ss_store_sk, ss_item_sk, ss_net_profit
        FROM store_sales
    UNION ALL
    SELECT sr_returned_date_sk, sr_store_sk, sr_item_sk, -sr_net_loss
        FROM store_returns
)
select count(*)
FROM sales_and_returns
JOIN date_dim
    -- strict column-to-column predicate
  ON d_date_sk = ss_sold_date_sk
-- note: this join is "bad", but serves as demonstration case
JOIN inventory
  ON inv_item_sk = ss_item_sk
  -- join condition not part of the sales/date join
  AND d_date_sk = ss_sold_date_sk
WHERE d_date = DATE '2002-10-03'

== EXPECT: inversion
-->

---

**Unsupported Cases:**

```sql
FROM sales_and_returns
JOIN date_dim
    -- expressions on either side
  ON TRIM(d_date_sk) = TRIM(ss_sold_date_sk)
```

<!--
== TEST QUERY 13 ==
WITH sales_and_returns AS (
    -- typically, this is not part of the query, but hidden
    -- in some view providing a unified data source
    SELECT ss_sold_date_sk, ss_store_sk, ss_net_profit
        FROM store_sales
    UNION ALL
    SELECT sr_returned_date_sk, sr_store_sk, -sr_net_loss
        FROM store_returns
)
select count(*)
FROM sales_and_returns
JOIN date_dim
    -- strict column-to-column predicate
  ON d_date_sk+1 = ss_sold_date_sk
WHERE d_date = DATE '2002-10-03'

== EXPECT: no inversion
-->

```sql
FROM sales_and_returns
-- note: this join is "bad", but serves as demonstration case
JOIN inventory
  ON inv_item_sk = ss_item_sk
JOIN date_dim
  -- filtering table joins on another table
  ON d_date_sk = ss_sold_date_sk
  AND d_date_sk = inv_date_sk
```

**Note:** Swapping `inventory` and `dim_date` in the SQL text along with their join conditions would turn this into a supported case...

<!--
== TEST QUERY 14 ==
WITH sales_and_returns AS (
    -- typically, this is not part of the query, but hidden
    -- in some view providing a unified data source
    SELECT ss_sold_date_sk, ss_store_sk, ss_net_profit, ss_item_sk
        FROM store_sales
    UNION ALL
    SELECT sr_returned_date_sk, sr_store_sk, -sr_net_loss, sr_item_sk
        FROM store_returns
)
select count(*)
FROM sales_and_returns
-- note: this join is "bad", but serves as demonstration case
JOIN inventory
  ON inv_item_sk = ss_item_sk
JOIN date_dim
  -- filtering table joins on another table
  ON d_date_sk = ss_sold_date_sk
  AND d_date_sk = inv_date_sk
WHERE d_date = DATE '2002-10-03'

== EXPECT: no inversion
-->

```sql
FROM sales_and_returns
-- note: this join is "bad", but serves as demonstration case
JOIN inventory
  ON inv_item_sk = ss_item_sk
JOIN date_dim
  -- filtering table does not directly join to union
  ON d_date_sk = inv_date_sk
```

**Note:** Providing another supported predicate on `inventory` (like `inv_warehouse_sk = 3`) would enable iterative pushing of both joins.
<!-- meta: verified 2025-04-17, Exasol 0.34.0 -->

<!--
== TEST QUERY 15 ==
WITH sales_and_returns AS (
    -- typically, this is not part of the query, but hidden
    -- in some view providing a unified data source
    SELECT ss_sold_date_sk, ss_store_sk, ss_net_profit, ss_item_sk
        FROM store_sales
    UNION ALL
    SELECT sr_returned_date_sk, sr_store_sk, -sr_net_loss, sr_item_sk
        FROM store_returns
)
select count(*)
FROM sales_and_returns
-- note: this join is "bad", but serves as demonstration case
JOIN inventory
  ON inv_item_sk = ss_item_sk
JOIN date_dim
  -- filtering table does not directly join to union
  ON d_date_sk = inv_date_sk
WHERE d_date = DATE '2002-10-03'

== EXPECT: no inversion
-->

### 6: Limit Number Of Added Columns

As the size of the materialization also depends on the number of columns needed, the following limit applies:

- given `NU` as number of *required* columns of the UNION ALL
- given `NT` as number of *required* columns of the joined table
- `if NT >= 6 AND NT > NU` then **do not push**

In other words: The inversion is allowed if it adds less than six columns or at most doubles the number of columns in the union.

**Notes:**

- *required columns* for the union are all columns in its select list that are actually referenced outside the union all
- *required columns* for the joined table are all columns that are required to process the remainder of the query
- As indicated above, multiple join filters may be applicable, so a table violating this limit in the first check may find a higher value for `NU` after another join was pushed into the union...

## References

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
