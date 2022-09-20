# How to implement KEEP (DENSE_RANK FIRST/LAST ORDER BY &lt;expr&gt;) in EXASOL 
## Background

* This solution is currently work in progress, but published anyway
* Aggregation with KEEP FIRST/LAST workaround is given in this solution. We will try to add a workaround for analytical functions with KEEP FIRST/LAST
* All Joins in our examples are not taking care about potential NULL values. For NULL values a join condition using NVL or similar should be used
* No warranty for correctness

## How to transform the following select to something supported in EXASOL?

Note: The following transformation is an advanced topic. Understanding how to rewrite the query will need a considerable amount of time.


```"code-sql"
SELECT   <aggregate_function>(<aggregate_args>) KEEP (DENSE_RANK FIRST/LAST ORDER BY <order_expr>)   <other_select_list_exprs> FROM   <from_clause> WHERE   <where_clause> GROUP BY   <group_by_cols> HAVING   <having_clause> 
```
DENSE_RANK KEEP FIRST/LAST calculate the <aggregate_function> only on those values of <aggregate_args> that have the highest / lowest values in <order_expr>.

In order to rewrite the statement we need to calculate:

## *Step 1*

<other_select_list_exprs> with the original GROUP BY

## *Step 2*

<aggregate_function>(<aggregate_args>) for a GROUP BY <group-by_cols>,<order_expr>. This computes the aggregates for each value of order_expr, so among others - which will be discarded - there is the computation for the FIRST and LAST value

## *Step 3*

The minimum/maximum value of <order_expr> for the original GROUP BY. This is needed to determine which subgroup to select from the finer aggregates.

The values for the original select from (1) will then be enriched with values from (2) by a join on the GROUP BY-columns of the original select together with the attribute for selecting exactly the <aggregate_function> value for the subaggregation for the FIRST / LAST value.

So basically, the rewriting looks like this:


```"code-sql"
WITH original_aggregation AS (   SELECT     <other_select_list_exprs>,     min/max(<order_expr>) AS first_last_selector,     <group_by_cols>   FROM     <from_clause>   WHERE     <where_clause>   GROUP BY     <group_by_cols>   HAVING     <having_clause> ), subaggregate_for_first_last AS (   SELECT     <aggregate_function>(<aggregate_args>) AS afk,     <group_by_cols>,     <order_expr>   FROM     <from_clause>   WHERE     <where_clause>   GROUP BY     <group_by_cols>, <order_expr>   HAVING     <having_clause> -- not needed and not accurate, but filters anyway ) -- Now the join SELECT   sub_agg.afk,   orig_agg.<other_select_list_expr> FROM     original_aggregation AS orig_agg   LEFT JOIN subaggregate_for_first_last AS sub_agg   ON orig_agg.<group_by_cols> = sub_agg.<group_by_cols>      AND orig_agg.first_last_selector = sub_agg.<order_expr> 
```
To get the computation faster, we don't use a separate select for 1) and 2), but combine the calculation in a single select with different GROUPING SETs and distinguish them by the different values of the GROUPING-function (see manual for more details):


```"code-sql"
WITH all_aggregations AS (   SELECT     <aggregate_function>(<aggregate_args>) AS afk,     <other_select_list_exprs>,     min/max(<order_expr>) AS first_last_selector,     <group_by_cols>,     <order_expr>,     GROUPING(<group_by_cols>, <order_expr>) AS group_selector   FROM     <from_clause>   WHERE     <where_clause>   GROUP BY     GROUPING SETS ((<group_by_cols>), (<group_by_cols>, <order_expr>))   HAVING       <having_clause> ), original_aggregation AS (   SELECT     <other_select_list_exprs>,     first_last_selector,     <group_by_cols>,   FROM     all_aggregations    WHERE     group_selector=<GROUPING value for aggregate on <group_by_cols> only> ), subaggregate_for_first_last AS (   SELECT     afk,     <group_by_cols>,     <order_expr>   FROM     all_aggregations    WHERE     group_selector=<GROUPING value for aggregate on <group_by_cols> and <order_expr>> ) -- Now the join SELECT   sub_agg.afk,   orig_agg.<other_select_list_expr> FROM     original_aggregation AS orig_agg   LEFT JOIN subaggregate_for_first_last AS sub_agg   ON orig_agg.<group_by_cols> = sub_agg.<group_by_cols>      AND orig_agg.first_last_selector = sub_agg.<order_expr> 
```
### Example of a simple transformation


```"code-sql"
-- Sample data table CREATE TABLE T (i int, gc int, j int, k int); INSERT INTO T VALUES   (1, 1, 3, 1),   (2, 1, 5, 1),   (3, 1, 7, 2),   (4, 1, 9, 3),   (5, 1, 11, 3),   (6, 2, 7, 1),   (7, 2, 3, 2);  -- This select SELECT   max(i) AS col,   sum(j) KEEP (DENSE_RANK FIRST ORDER BY k) kdrf FROM t GROUP BY gc;  -- With result -- col kdrf -- 5 8 (=3+5, values 7, 9 and 11 are not aggregated) -- 7 7 (=7, value 3 is not aggregated)  -- Is transformed to WITH all_aggregations AS (   SELECT     sum(j) AS afk,     max(i) as col,     min(k) AS first_last_selector,     gc,     k,     GROUPING(gc, k) AS group_selector   FROM t   GROUP BY GROUPING SETS ((gc), (gc, k)) ), original_aggregation AS (   SELECT     col,     first_last_selector,     gc   FROM all_aggregations    WHERE group_selector=1 ), subaggregate_for_first_last AS (   SELECT     afk,     gc,     k   FROM all_aggregations    WHERE group_selector=0 ) -- Now the join SELECT   orig_agg.col,   sub_agg.afk as kdrf FROM     original_aggregation AS orig_agg   LEFT JOIN subaggregate_for_first_last AS sub_agg   ON orig_agg.gc = sub_agg.gc      AND orig_agg.first_last_selector = sub_agg.k ; 
```
## Additional Notes

### What to do with aggregated select (no GROUP BY)

The case that KEEP DENSE RANK FIRST/LAST is used in an aggregated select without GROUP BY is a simpler special case of the case with GROUP BY. In that case we add aGROUP BY GROUPING SETS (), (<order_expr>)and join on only onfirst_last_selector=order_expr. Essentially everything is the same in that case, only we can omit<group_by_cols>whereever they were used.

### Transformation for multiple FIRST/LAST functions

Note that in the case of a single KEEP DENSE_RANK FIRST/LAST function the value of the group_selector in the WITH-clause subaggregate_for_first_last is 0.

However, we can do the same transformation for multiple KEEP DENSE_RANK FIRST/LAST functions. In the general case we need a separate subaggregation for each KEEP DENSE_RANK FIRST/LAST function - which means another GROUPING SET (<group_by_cols>, <new_order_expr>), another WITH-clause with selection of the correct GROUPING and another LEFT JOIN on <group_by_cols> and <first_last_selector> for that <new_order_expr>.

A few tweaks can be applied to the general case in some situations:

* if multiple KEEP DENSE_RANK FIRST/LAST functions share the same <order_expr> their <aggregate_function>-values can be computed in the same subaggregate_select (and same GROUPING SET), but might still need a sepate LEFT JOIN for each
* if they further have the same value of FIRST/LAST and have the same ORDER BY direction a single LEFT JOIN on this select is enough to get all the correct values.

### Example of a transformation with several FIRST/LAST

### Matrix for first_last_selector

The following expressions need to be used as first_last_selector depending on FIRST/LAST and ORDER BY clause:



| ORDER BY | FIRST | LAST |
| --- | --- | --- |
| ASC[NULLS LAST] | min(<order_expr>) | CASE WHEN COUNT(<order_expr>)!=COUNT    THEN NULL ELSE max(<order_expr>) END |
| DESC[NULLS FIRST] | CASE WHEN COUNT(<order_expr>)!=COUNT    THEN NULL ELSE max(<order_expr>) END | min(<order_expr>) |
| ASC NULLS FIRST | CASE WHEN COUNT(<order_expr>)!=COUNT    THEN NULL ELSE min(<order_expr>) END | max(<order_expr>) |
| DESC NULLS LAST | max(<order_expr>) | CASE WHEN COUNT(<order_expr>)!=COUNT    THEN NULL ELSE min(<order_expr>) END |

### Multiple <order_by_expr>s

If there are multiple <order_expr>s for a single KEEP DENSE_RANK FIRST/LAST function things get more complicated:

* In that case we can try to combine them all in a single value by concatenating them (and padding, such that order of the values is the same as for the concatenated values. This will work as long as all columns have the same ORDER BY direction
* Otherwise we might need to add a subselect around the <from_clause> containing <from>.* and RANK() OVER (ORDER BY <order_by_expr>s) as rnk. Then we can use MIN(CASE WHEN rnk=1 THEN <order_by_expr> ELSE NULL) for each <order_by_expr> to get multiple first_last_selectors for the LEFT JOIN. Of course, this would need to be done for each KEEP DENSE_RANK FIRST/LAST function with multiple <order_by_expr>s.

## Additional References

<https://www.exasol.com/support/browse/IDEA-65>

