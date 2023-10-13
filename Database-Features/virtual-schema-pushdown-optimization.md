# Pushdown optimization for queries to Virtual schemas

## Problem
There are a couple of situations which trigger the optimizer to rewrite the query with no regard to virtual schema (VS) pushdown optimization. So the following circumstances can ruin pushdown performance:
* direct joins between objects from the different schemas (local and virtual)
* multiple nested view layers on top of VS object
* CTEs ( or "with" clause) for a subquery with VS objects or their derivatives
* multiple usages of the same VS based view in a single subquery

Except the first one (it is critical in every scenario), each case by itself usually is not critical and performs as expected. But combinations of those situations may lead to separate pushdowns for each VS object.

## How to avoid the problem. Tips.
Below you can find some tips and examples which hopefully will help you to avoid those situations:

* First of all, if VS objects are directly joined together with other sources (local tables, objects based on  another VS) this always leads to separate pushdowns. To avoid this you should always try to join only objects from a particular VS in one subquery and then use this subquery's results to join with other sources.

* Important point: it is also crucial to forbid the optimizer to break down such subquery and mix it up with objects from other sources. To do so you should always force materialization of those subqueries. Materialization is happening when sort operation is performed: for example when you use "distinct" or "order by" etc..

* In Exasol there is a special way to trigger materialization even if sorting is not needed: "order by false". This actually will not cause any costly and unnecessary sorting, but the optimizer will act the same way as with sorting and will materialize the dataset. So to be sure that your subquery with VS objects will not be broken apart, always use "order by false" at the end of it.

**Example:**
even if you use VS objects themselves (not views on top of them) without any CTEs, this query will give you multiple pushdowns because VS objects are directly joined with local objects:
```sql
explain virtual

SELECT
    op.rechnungsnr
FROM VIRTUAL_SCHEMA.dax_akq_syr_op_a op
INNER JOIN VIRTUAL_SCHEMA.dax_akq_syr_opdetail_a               opd2 ON op.boid = opd2.itsdet_op
INNER JOIN VIRTUAL_SCHEMA.dax_akq_syr_opdetail_a               opd3 ON op.boid = opd3.itsdet_op
INNER JOIN LOCAL_SCHEMA.sale s on op.rechnungsnr = s.id;
```

The next query is better, because we have all VS tables grouped together in one subquery VS_SUBQ and no other tables are mixed into it. But still it may result in a multiple pushdowns, if optimizer decides to rewrite the query and break apart the subquery:
```sql
explain virtual
select
        VS_SUBQ.rechnungsnr
from
(SELECT
    op.rechnungsnr
FROM VIRTUAL_SCHEMA.dax_akq_syr_op_a op
INNER JOIN VIRTUAL_SCHEMA.dax_akq_syr_opdetail_a               opd2 ON op.boid = opd2.itsdet_op
INNER JOIN VIRTUAL_SCHEMA.dax_akq_syr_opdetail_a               opd3 ON op.boid = opd3.itsdet_op
) VS_SUBQ

INNER JOIN LOACL_SCHEMA.sale s on VS_SUBQ.rechnungsnr = s.CASH_OR_PLASTIC;
```

Finally If we materialize the subquery, then only a single pushdown will be issued:
```sql
explain virtual
select
        VS_SUBQ.rechnungsnr
from
(SELECT
    op.rechnungsnr
FROM VIRTUAL_SCHEMA.dax_akq_syr_op_a op
INNER JOIN VIRTUAL_SCHEMA.dax_akq_syr_opdetail_a               opd2 ON op.boid = opd2.itsdet_op
INNER JOIN VIRTUAL_SCHEMA.dax_akq_syr_opdetail_a               opd3 ON op.boid = opd3.itsdet_op
order by false
) VS_SUBQ

INNER JOIN LOACL_SCHEMA.sale s on VS_SUBQ.rechnungsnr = s.CASH_OR_PLASTIC;
```

* If you need to use multiple different virtual schemas in one query, use described approach to have a dedicated subquery for each VS.

**Example:** here we have 2 pushdowns to VIRTUAL_SCHEMA1 and VIRTUAL_SCHEMA2.
```sql
explain virtual
select 
        VS_SUBQ1.rechnungsnr
from
(SELECT
    op.rechnungsnr
FROM VIRTUAL_SCHEMA1.dax_akq_syr_op_a op
INNER JOIN VIRTUAL_SCHEMA1.dax_akq_syr_opdetail_a               opd2 ON op.boid = opd2.itsdet_op
INNER JOIN VIRTUAL_SCHEMA1.dax_akq_syr_opdetail_a               opd3 ON op.boid = opd3.itsdet_op
order by false
) VS_SUBQ1
INNER JOIN

(SELECT
    op.rechnungsnr
FROM VIRTUAL_SCHEMA2.dax_akq_syr_op_a op
INNER JOIN VIRTUAL_SCHEMA2.dax_akq_syr_opdetail_a               opd2 ON op.boid = opd2.itsdet_op
INNER JOIN VIRTUAL_SCHEMA2.dax_akq_syr_opdetail_a               opd3 ON op.boid = opd3.itsdet_op
order by false
) VS_SUBQ2 ON VS_SUBQ1.rechnungsnr = VS_SUBQ2.rechnungsnr

INNER JOIN LOACL_SCHEMA.sale s on VS_SUBQ1.rechnungsnr = s.CASH_OR_PLASTIC;
```

* The same applies when it is logically impossible to join together all objects from a single VS and you have multiple independent subqueries. Try to organize each subquery as described above and you should have 1 pushdown per subquery. 
* Regarding CTEs ("with" clause), try to avoid using them for VS object subqueries. In combination with nested view-layers on top of VS objects and multiple usage of the same VS object, CTEs are causing not optimal query rewriting and as a result - multiple pushdowns. You can use CTE for the other things inside your query though, for example for local objects.

**Example:** even though we've separated all VS objects into a single CTE and tried to materialize it with "order by false", it still spawns multiple pushdowns because of using the same object twice (VS_VIEWS_LAYER1.dax_akq_syr_opdetail_a ) in combination with view layer on top of VS tables.
```sql
explain virtual
with VS_SUBQ as(
select
    op.rechnungsnr
FROM VS_VIEWS_LAYER1.dax_akq_syr_op_a op
INNER JOIN VS_VIEWS_LAYER1.dax_akq_syr_opdetail_a               opd2 ON op.boid = opd2.itsdet_op
INNER JOIN VS_VIEWS_LAYER1.dax_akq_syr_opdetail_a               opd3 ON op.boid = opd3.itsdet_op
order by false
) 
select * from VS_SUBQ
INNER JOIN LOACL_SCHEMA.sale s on VS_SUBQ.rechnungsnr = s.CASH_OR_PLASTIC;
```
But if we use the same subquery not as CTE but just as a regular subquery in "from" clause, we get a single pushdown:
```sql
explain virtual
select * from 
(select
    op.rechnungsnr
FROM VS_VIEWS_LAYER1.dax_akq_syr_op_a op
INNER JOIN VS_VIEWS_LAYER1.dax_akq_syr_opdetail_a               opd2 ON op.boid = opd2.itsdet_op
INNER JOIN VS_VIEWS_LAYER1.dax_akq_syr_opdetail_a               opd3 ON op.boid = opd3.itsdet_op
order by false) VS_SUBQ
INNER JOIN LOACL_SCHEMA.sale s on VS_SUBQ.rechnungsnr = s.CASH_OR_PLASTIC;
```
Adding the CTE with local tables in it doesn't affect our pushdown optimization:
```sql
explain virtual
with LOCAL_CTE as
(
select 
s.CASH_OR_PLASTIC 
from LOCAL_SCHEMA.sale s
inner join LOCAL_SCHEMA.CASH_POINT cp on cp.CASH_POINT_NR = s.CASH_POINT_NR
)

select * from 
(select
    op.rechnungsnr
FROM VS_VIEWS_LAYER1.dax_akq_syr_op_a op
INNER JOIN VS_VIEWS_LAYER1.dax_akq_syr_opdetail_a               opd2 ON op.boid = opd2.itsdet_op
INNER JOIN VS_VIEWS_LAYER1.dax_akq_syr_opdetail_a               opd3 ON op.boid = opd3.itsdet_op
order by false) VS_SUBQ
INNER JOIN LOCAL_CTE s on VS_SUBQ.rechnungsnr = s.CASH_OR_PLASTIC;
```
* The same idea with multiple nested view layers on top of the VS objects. Try to limit it to only 1 view layer, because 2 and more nesting views over the VS tables already may confuse the optimizer in some situations.

## So to sum this all up:
* Group objects from the same VSs in dedicated subqueries. Each subquery should result in 1 pushdown.
* Avoid mixing other sources (local schemas, other VSs) to such subqueries.
* Always materialize those VS subqueries with help of "order by false".
* Avoid using "with" clause for VS subqueries. You can use them for the local schemas though.
* Try to avoid using more than 1 view on top of each VS object. 
