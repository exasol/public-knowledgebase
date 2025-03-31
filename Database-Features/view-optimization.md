# View Optimization

Note: This article describes the Exasol optimizer feature "View Optimization"; it does not give tips on how to optimize views manually.

## Background: Other Optimizations

Views in Exasol can contain arbitrary logic, and return anything from zero to billions of rows. As the main goal of Exasol's optimizer is to minimize RAM usage, it will do its best to 'eliminate' views and subselects (*subselect elimination* would be another article) by embedding their logic into the parent query, or at least push as many filters as possible into the view before it gets materialized (another missing article: *filter propagation*).

### Examples

Notes:

- all query rewrites are performed on the compiled query graph, not in SQL text as shown below.
- all queries are based on a TPC-DS data set of 10 GB (scale factor 10). The TPD-DS data generator always creates data for the years 1998 through 2003.

```sql
-- original query: materialized view would contain 7 million rows
WITH big_sales AS (
    SELECT * FROM catalog_sales
    WHERE cs_quantity > 50
)
SELECT 
    d_year, SUM(cs_net_paid) as turnover
FROM big_sales
JOIN date_dim
  ON d_date_sk = cs_sold_date_sk
GROUP BY d_year;

-- after subselect elimination: no intermediate materialization
SELECT 
    d_year, SUM(cs_net_paid) as turnover
FROM catalog_sales
JOIN date_dim
  ON d_date_sk = cs_sold_date_sk
WHERE cs_quantity > 50
GROUP BY d_year;
```

```sql
-- original query: materialized view would process 14 million records
WITH yearly_turnover AS (
    SELECT 
        d_year, SUM(cs_net_paid) as turnover
    FROM catalog_sales
    JOIN date_dim
      ON d_date_sk = cs_sold_date_sk
   GROUP BY d_year
)
SELECT SUM(turnover)
FROM yearly_turnover
WHERE d_year >= 2002;

-- after filter propagation: processes 3 million records
WITH yearly_turnover AS (
    SELECT 
        d_year, SUM(cs_net_paid) as turnover
    FROM catalog_sales
    JOIN date_dim
      ON d_date_sk = cs_sold_date_sk
   WHERE d_year >= 2002
   GROUP BY d_year
)
SELECT SUM(turnover)
FROM yearly_turnover
;
```

## Multiple Usages: View Optimization

The mechanics above are usually pretty straight-forward and rarely cause problems.

However, things get more complicated when a view is **used multiple times** within a statement:

### Example

```sql
WITH yearly_turnover AS (
    SELECT 
        d_year, SUM(cs_net_paid) as turnover
    FROM catalog_sales
    JOIN date_dim
      ON d_date_sk = cs_sold_date_sk
   GROUP BY d_year
)
SELECT 'previous' AS "YEAR", SUM(turnover) AS turnover
  FROM yearly_turnover WHERE d_year = 2002
UNION ALL
SELECT 'current', SUM(turnover)
  FROM yearly_turnover WHERE d_year = 2003
;
```

The optimizer now has to decide between the following two options. This decision is called **view optimization** at Exasol.

### 1 - Materialize the view once

...and reuse its data in all occurrences. This will guarantee identical data in all places, but might cause excessive RAM usage if the view returns too much &mdash; potentially unused &mdash; data.

In the example above, this would again cause processing of 14 million rows, followed by two very quick filters.

### 2 - Treat each occurrence separately

...and apply the mechanisms outlined in [Background](#background-other-optimizations) above. While this will usually result in much smaller materializations (or none at all), it will potentially incur duplicate processing efforts and might &mdash; at least in theory &mdash; return inconsistent data due to unpredictable rounding errors in each evaluation.

In the given example, this is the decision taken by the optimizer. The query is converted into:

```sql
SELECT 'previous' AS "YEAR", SUM(turnover) FROM (
    SELECT 
        d_year, SUM(cs_net_paid) as turnover
    FROM catalog_sales
    JOIN date_dim
      ON d_date_sk = cs_sold_date_sk
   GROUP BY d_year
) WHERE d_year = 2002
UNION ALL
SELECT 'current', SUM(turnover) FROM (
    SELECT 
        d_year, SUM(cs_net_paid) as turnover
    FROM catalog_sales
    JOIN date_dim
      ON d_date_sk = cs_sold_date_sk
   GROUP BY d_year
) WHERE d_year = 2003;
```

And at this point, the *filter propagation* shown earlier comes into play, converting the query into:

```sql
SELECT 'previous' AS "YEAR", SUM(turnover) FROM (
    -- processes 2 million rows
    SELECT 
        d_year, SUM(cs_net_paid) as turnover
    FROM catalog_sales
    JOIN date_dim
      ON d_date_sk = cs_sold_date_sk
   WHERE d_year = 2002
   GROUP BY d_year
)
UNION ALL
SELECT 'current', SUM(turnover) FROM (
    -- processes 60k rows
    SELECT 
        d_year, SUM(cs_net_paid) as turnover
    FROM catalog_sales
    JOIN date_dim
      ON d_date_sk = cs_sold_date_sk
   WHERE d_year = 2003
   GROUP BY d_year
);
```

---

Notes - valid for all Exasol versions at time of writing (8.32.0)

- Unfortunately, this decision is purely based on the query structure around the view usages, and does not take into account the view itself or any statistics of the tables involved &mdash; there is **no way** to influence this optimization by changing the view in question, for example by adding `ORDER BY FALSE`.
- A view is a view, a CTE is a CTE and a subselect is a subselect:
  - In most cases, CTEs are treated as views, but there might be subtle differences.
  - Subselects are always treated individually, even when they contain the exact same SQL text.
<!-- TODO: future reference to Changelog-Entry-23792, which should address the "multiple identical subselect" part -->

---

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
