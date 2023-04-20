# Multi-path SQL: Tables vs. Views vs. Subselects 
## Background

Often, an analysis will be complex enough that it is very hard or cumbersome to express in a single SQL statement. To get around this, there are usually several approaches:

* Temporary Tables
* Views
* Subselects

## Conventional Method: Temporary Tables

The usual way to work around this is to create temporary tables with intermediate results and then combine those in a 'final' select statement:


```"code-sql"
CREATE TABLE german_cities AS
(
       SELECT cities.* FROM cities, countries
       WHERE
              cities.country_id=countries.country_id
              AND countries.name='Germany'
);
 
SELECT b.name, c.name, count(*)
FROM
       customer_moves a,
       german_cities b, german_cities c
WHERE
        a."from" = b.city_id AND
        a."to" = c.city_id
GROUP BY b.name, c.name;

ROLLBACK; -- Does not persist the table
```
However, this has some side-effects:

* The user/application has to take care of namespace-congestion, as every session will have to create their own (uniquely named) tables.
* Filters that are to be applied to the final select will have to be (manually) integrated into the creation of the temporary tables, or they might get unnecessary big.
* Whenever the base data changes, the (temporary) tables need to be updated or the analysis might give outdated results.

Please note that Exasol does not know the concept of temporary tables. As this is an in-memory database and we really stick to the ACID rules, every table can be interpreted as temporary until it is committed.

So if you implement multi-path SQL using intermediate tables, we suggest you turn off auto-commit for this and drop the tables when the analysis is complete. After that, it is 'safe' to commit your changes (if any).

## Better way: Views

The better solution, in this case, is to replace the temporary tables with views, giving the following side-effects

* Exasol's optimizer can see the big picture in the final select. It can choose to rearrange join orders, maybe even cross-reference conditions that originally were local in different views.
* The same holds true to additional conditions that are applied in the final select: They can usually be propagated down to low levels, reducing the amount of data flowing through the query graph very early.
* There is no outdated data. The views always access the currently valid (committed) fact data.


```"code-sql"
CREATE VIEW german_cities AS
(
       SELECT cities.* FROM cities, countries
       WHERE
              cities.country_id=countries.country_id
              AND countries.name='Germany'
);
 
SELECT b.name, c.name, count(*)
FROM
       customer_moves a,
       german_cities b, german_cities c
WHERE
        a."from" = b.city_id AND
        a."to" = c.city_id
GROUP BY b.name, c.name;
```
But in the case where the multi-path query is generated on the fly by some application, you still have the overhead of views being created and possible namespace clashes.

## All-in-one: Named Subselects

In these cases, named subselects (also called Common Table Expressions or CTEs) might be just what you've been looking for.

Basically, they work like views, but they are not database objects. Instead they are parts of your query. No need to create them, drop them, commit them: No overhead, but still all the flexibility you wish for:


```"code-sql"
WITH german_cities AS
(
       SELECT cities.* FROM cities, countries
       WHERE
              cities.country_id=countries.country_id
              AND countries.name='Germany'
)
SELECT b.name, c.name, count(*)
FROM
       customer_moves a,
       german_cities b, german_cities c
WHERE
        a."from" = b.city_id AND
        a."to" = c.city_id
GROUP BY b.name, c.name;
```
## Additional References

* [CREATE VIEW Syntax](https://docs.exasol.com/sql/create_view.htm)
* [SELECT syntax](https://docs.exasol.com/sql/select.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 