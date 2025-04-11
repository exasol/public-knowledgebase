# Hiding Join Conditions

<!-- meta
   LAST_VERIFIED: Exasol 8.33.0
-->

## Problem

While Exasol's query optimizer is quite smart in some places, it can be stubborn in others.
One such stubborn place is located in join index creation:

For any join, the query engine will always request &mdash; and create, if necessary &mdash; an index containing all columns that are referred using equality-join conditions[^eqj]:

[^eqj]: Equality operator, and one side of the operation contains only columns of the adjoined table.

This can lead to the different problems as shown below.

**Notes:**

- All examples use the TPC-DS data model
- All examples use `LEFT JOIN` to enforce a join order for demonstration purposes
- The smart part of Exasol's query optimizer might 'construct' the situations below by transporting or copying given conditions from `HAVING` to `WHERE` clauses and from `WHERE` to the respective JOIN operations[^conversion].
For example, even if all joins inside a view are well-formed and contain only the necessary columns, filter conditions provided when selecting from the view may change join columns.

[^conversion]: Note that any `WHERE` condition on an inner table that does not handle null values will automatically convert the respective join to an *inner join*.

### 1 - Extra Index Columns

```sql
SELECT count(*)
FROM customer
LEFT JOIN customer_address
   ON c_current_addr_sk = ca_address_sk
   AND c_birth_country = ca_country
```

Even though `ca_address_sk` is actually a primary key, the query engine wants to join on both columns to get maximum index selectivity:

|PART_ID|PART_NAME|PART_INFO|OBJECT_NAME|REMARKS|
|---|---|---|---|---|
|1|COMPILE / EXECUTE|(null)|(null)|(null)|
|2|INDEX CREATE|(null)|CUSTOMER_ADDRESS|GLOBAL INDEX (CA_ADDRESS_SK,CA_COUNTRY)|
|3|**INDEX CREATE**|on REPLICATED table|CUSTOMER_ADDRESS|**LOCAL INDEX (CA_ADDRESS_SK,CA_COUNTRY)**|
|4|SCAN|(null)|CUSTOMER|(null)|
|5|OUTER JOIN|on REPLICATED table|CUSTOMER_ADDRESS|CUSTOMER(C_CURRENT_ADDR_SK,C_BIRTH_COUNTRY) **=> LOCAL INDEX (CA_ADDRESS_SK,CA_COUNTRY)**|
|6|GROUP BY|GLOBAL on TEMPORARY table|tmp_subselect0|(null)|

### 2 - Duplicate Index Columns

```sql
SELECT count(*)
FROM customer
LEFT JOIN customer_address
   ON c_current_addr_sk = ca_address_sk
   AND c_current_addr_sk = ca_address_sk
```

This will indeed create and use an index with two columns:

|PART_ID|PART_NAME|PART_INFO|OBJECT_NAME|REMARKS|
|---|---|---|---|---|
|1|COMPILE / EXECUTE|(null)|(null)|(null)|
|2|INDEX CREATE|(null)|CUSTOMER_ADDRESS|GLOBAL INDEX (CA_ADDRESS_SK,CA_ADDRESS_SK)|
|3|**INDEX CREATE**|on REPLICATED table|CUSTOMER_ADDRESS|**LOCAL INDEX (CA_ADDRESS_SK,CA_ADDRESS_SK)**|
|4|SCAN|(null)|CUSTOMER|(null)|
|5|OUTER JOIN|on REPLICATED table|CUSTOMER_ADDRESS|CUSTOMER(C_CURRENT_ADDR_SK) **=> LOCAL INDEX (CA_ADDRESS_SK,CA_ADDRESS_SK)**|
|6|GROUP BY|GLOBAL on TEMPORARY table|tmp_subselect0|(null)|

### 3 - Expression Indices

```sql
SELECT count(*)
FROM customer
LEFT JOIN customer_address
   ON c_current_addr_sk = ca_address_sk
   AND c_birth_country = ca_country
   AND c_birth_year = to_number(ca_zip) + ca_gmt_offset
```

Compiler accepts the third condition as an equality-join condition, resulting in an expression index:

|PART_ID|PART_NAME|PART_INFO|OBJECT_NAME|REMARKS|
|---|---|---|---|---|
|1|COMPILE / EXECUTE|(null)|(null)|(null)|
|2|**INDEX CREATE**|**EXPRESSION INDEX** on REPLICATED table|CUSTOMER_ADDRESS|**ExpressionIndex**|
|3|SCAN|(null)|CUSTOMER|(null)|
|4|OUTER JOIN|on REPLICATED table|CUSTOMER_ADDRESS|CUSTOMER(C_CURRENT_ADDR_SK,C_BIRTH_YEAR,C_BIRTH_COUNTRY) **=> ExpressionIndex**|
|5|GROUP BY|GLOBAL on TEMPORARY table|tmp_subselect0|(null)|

Beyond the obvious resource usage and storage problems caused by cases 1 and 2, expression indices are even worse: They cannot be stored and reused -- which means that index will be **re-created for every execution** of a query with such a join!

## Solution

Currently, the only "good" solution to this problem is to manually rewrite (*mask* or *hide*) the offending conditions so they are no longer detected as join conditions.

One very simple way to do so is to violate the "only one table" part of the equality-join condition by wrapping it in a boolean comparison:

```sql
SELECT count(*)
FROM customer
LEFT JOIN customer_address
   ON c_current_addr_sk = ca_address_sk
   AND TRUE = (
      c_birth_country = ca_country
      AND c_birth_year = to_number(ca_zip) + ca_gmt_offset
   )
```

Now, one side of the equality operator (`TRUE`) references no tables at all, and the other side references multiple tables. As a result, the join is using an index on the primary key column only, but the additional filter is still handled within the join stage:

|PART_ID|PART_NAME|PART_INFO|OBJECT_NAME|REMARKS|
|---|---|---|---|---|
|1|COMPILE / EXECUTE|(null)|(null)|(null)|
|2|SCAN|(null)|CUSTOMER|(null)|
|3|OUTER JOIN|on REPLICATED table|CUSTOMER_ADDRESS|CUSTOMER(C_CURRENT_ADDR_SK) **=> GLOBAL INDEX (CA_ADDRESS_SK)**|
|4|GROUP BY|GLOBAL on TEMPORARY table|tmp_subselect0|(null)|

## Additional References

- Documentation on query profiling: [https://docs.exasol.com/database_concepts/profiling.htm](https://docs.exasol.com/database_concepts/profiling.htm)
- Knowledgebase Article [Best-practice-Datatypes-and-Joins](https://exasol.my.site.com/s/article/Best-practice-Datatypes-and-Joins)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
