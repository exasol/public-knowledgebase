# Enforcing materializations with ORDER BY FALSE in subselects, views or CTEs 
Sometimes it is useful to enforce a materialization of a subselect (or view or CTE) by adding an ORDER BY FALSE to it.  
Those cases include:

1. Late applied filter (see below example)
2. Replace global by local join (by enforcing a materialization of a subselect that is smaller than replication border [see [replication-border-in-exasol-6-1](https://community.exasol.com/t5/database-features/replication-border-in-exasol-6-1/ta-p/1727)] with local filters)
3. Manual precalculation of multiple usages of subselects, views, CTEs

Please be aware that materializations can cause a lot of temporary data if they are big which might result in block swapping and decrease thoughput.

For example this query might not run optimal:

```"code-sql"
select ma.market_id , ma.city , max (amount) max_articles_sold,
avg (amount) avg_articles_sold from markets ma left join sales s on ma.market_id = s.market_id
join sales_positions sp on s.sales_id = sp.sales_id
where s.sales_date = date'2014-03-17' or s.sales_date is null
group by ma.market_id, ma.city;
```

The filtering on SALES is quite selective. But the optimizer may decide to full scan MARKETS, then join SALES (which has a very long duration)  and filter SALES later.
Instead, the next query enforces a materialization of the filter on SALES first, then MARKETS is joined. The only puprose of the clause ORDER BY FALSE is to get that materialization:

```"code-sql"
with mat_sales as
(select market_id, sales_id from retail.sales where sales_date = date'2014-03-17'
order by false
)
select ma.market_id, ma.city, max (amount) max_articles_sold, avg (amount) avg_articles_sold
from markets ma left join mat_sales s on ma.market_id = s.market_id
join sales_positions sp on s.sales_id = sp.sales_id
group by ma.market_id, ma.city;
```

Mind that the optimizer is constantly improved, so a trick like that to improve the execution plan might not be required any more in later versions.
