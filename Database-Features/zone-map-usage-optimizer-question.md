# Why did the optimizer decide not to use the zone map?

* even though zone map is forced and
* the WHERE clause can be used to prune data?

## Authors

* [Peggy Schmidt-Mittenzwei](https://github.com/PeggySchmidtMittenzwei)
* [Georg Dotzler](https://github.com/narmion)

## Question

Even if you force zone map usage and our WHERE clause is prunable, the optimizer might still avoid using the zone map:

We have given the following DDL:

```sql
-- data model preparation
CREATE SCHEMA TEST;

CREATE OR REPLACE TABLE TEST.T1  (time_zones timestamp, sid int);
ALTER TABLE TEST.T1  DISTRIBUTE BY sid;
```

We insert data as follows:

```sql
INSERT INTO 
    TEST.T1
SELECT 
    ADD_DAYS(TIMESTAMP '2025-06-30 00:00:00', -ROUND(RANDOM(1,200),0))
  , RANGE_VALUE
FROM
    VALUES BETWEEN 1 AND 40000001;
```

We also include the following data to better explain the optimizer’s decisions:

```sql
INSERT INTO TEST.T1 VALUES
('2024-01-01 00:00:00',105 ),                         
('2024-01-01 00:00:00',20717),
('2024-01-01 00:00:00',5),
('2025-04-18 00:00:00',111),
('2025-06-02 00:00:00',5),
('2025-06-03 00:00:00',105),
('2025-06-04 00:00:00',20717),
('2025-06-05 00:00:00',5);
```

Next we add zone map enforcement:

```sql
ENFORCE ZONEMAP ON TEST.T1 (time_zones);
```

and add an index to the SID, which in real use cases can be created by join queries:

```sql
ENFORCE LOCAL INDEX ON  TEST.T1 (sid);
```

Let's run the following statement to see if the zonemap was used.

```sql
SELECT DISTINCT sid
FROM TEST.T1
WHERE time_zones between '2025-06-01 00:00:00' and '2025-06-06 00:00:00';
```

### Profiling of the execution plan without zone map usage

|PART_ID|PART_NAME|PART_INFO|OBJECT_SCHEMA|OBJECT_NAME|REMARKS|DURATION|OBJECT_ROWS|OUT_ROWS|TEMP_DB_RAM_PEAK|
|---|---|---|---|---|---|---|---|---|---|
|1|COMPILE / EXECUTE|(null)|(null)|(null)|(null)|0.025|(null)|(null)|82.5|
|2|SCAN|$${\color{red}(null)}$$|TEST|T1|(null)|0.041|40000009|1204436|82.5|
|3|GROUP BY|on TEMPORARY table|(null)|tmp_subselect0|(null)|0.005|0|1000|82.6|


Regarding [Exasol Zone maps documentation](https://docs.exasol.com/db/latest/performance/zonemaps.htm) in profiling, an operation that utilized the zone records will show WITH ZONEMAP in the PART_INFO field. Why we do not see zone map usage?

## Explanation

Let's break down why this can happen in Exasol:

Let us do the following test, and lets remove the index:

```sql
DROP LOCAL INDEX ON  TEST.T1 (sid);
```

> [!CAUTION]
> Only perform such manual indexing operations based on the advice and guidance of Exasol Support.

We run the query again:

```sql
SELECT DISTINCT sid
FROM TEST.T1
WHERE time_zones between '2025-06-01 00:00:00' and '2025-06-06 00:00:00';
```

### Profiling of the execution plan with zone map usage

|PART_ID|PART_NAME|PART_INFO|OBJECT_SCHEMA|OBJECT_NAME|REMARKS|DURATION|OBJECT_ROWS|OUT_ROWS|TEMP_DB_RAM_PEAK|
|---|---|---|---|---|---|---|---|---|---|
|1|COMPILE / EXECUTE|(null)|(null)|(null)|(null)|0.015|(null)|(null)|156.0|
|2|SCAN|$${\color{red}WITH ZONEMAP}$$|TEST|T1|T1(TIME_ZONES)|0.007|40000009|1204436|156.0|
|3|GROUP BY|on TEMPORARY table|(null)|tmp_subselect0|T1(SID)|0.070|0|1000|156.0|

> [!NOTE]
> From this example we see that the first pipeline speeds up the filter but slows down the GROUP BY.


In order to explain the problem sufficiently and simply, we have simplified the execution somewhat and use the additional data sets.

### Explanation of the execution plan without zone map usage

Let us go the first execution:

The SCAN uses the index on SID to identify the best ROWID order for the GROUP BY. So the data block layout after
the SCAN is:

|ROWID | TIMES_SEGMENT_ID | TIMES_VALUE  | SID_VALUE | 
|---|---|---|---|
|46    | 1                | '2020-01-01' | 5|
|65    | 6                | '2025-06-05' | 5|
|7348  | 5                | '2025-06-02' | 5|
|23    | 1                | '2020-01-01' | 105|
|3     | 5                | '2025-06-03' | 105|
|1234  | 5                | '2025-04-18' | 111|
|12    | 1                | '2020-01-01' | 20717|
|128   | 5                | '2025-06-04' | 20717|

The input is ordered as above. This means, engine reads the first entries and sees TIMES_SEGMENT_ID 1, 6, 5, 1, ...
Accessing the metadata of a segment has an overhead and also consumes memory.  So our engine only accesses the metadata if consecutive rows in the data block have the same SEGMENT_ID.

> [!NOTE]
> Due to that mixed up TIMES_SEGMENT_IDs, our database engine does not use zone maps for the filter although zone maps are available.

Now let us continue with the example.
After the PIPE FILTER filter stage down the data block layout is:

ROWID | TIMES_SEGMENT_ID | TIMES_VALUE  | SID
|---|---|---|---|
65    | 6                | '2025-06-05' | $${\color{green}5}$$
7348  | 5                | '2025-06-02' | $${\color{green}5}$$
3     | 5                | '2025-06-03' | 105
128   | 5                | '2025-06-04' | 20717

> [!IMPORTANT]
> This is the perfect input for the GROUP BY and considerable speeds up the following GROUP BY computation.

$\textsf{\color{green}{Reason: GROUP BY execution is faster if entries with the same key are executed together.}}$  

### Explanation of the execution plan with zone map usage

Here the SCAN scans the column TIMES and executes the filter. The scan part leads to the following data block layout:

ROWID | TIMES_SEGMENT_ID | TIMES_VALUE  | SID_VALUE
|---|---|---|---|
23    | 1                | '2020-01-01' | 105                            
12    | 1                | '2020-01-01' | 20717
46    | 1                | '2020-01-01' | 5
1234  | 5                | '2025-04-18' | 111
7348  | 5                | '2025-06-02' | 5
3     | 5                | '2025-06-03' | 105
128   | 5                | '2025-06-04' | 20717
65    | 6                | '2025-06-05' | 5

Let us assume the zone maps for the TIMES_SEGEMENT_IDs (1,2,3,4) have min = '2020-01-01' and max = '2020-01-01'.
This means the filter part of the scan can remove the segments 1,2,3,4 with zone maps and only needs to filter the rest.
Thus the data block layout for the next stage after the filter part of FILTERSCAN is

ROWID | TIMES_SEGMENT_ID | TIMES_VALUE  | SID
|---|---|---|---|
7348  | 5                | '2025-06-02' | $${\color{red}5}$$
3     | 5                | '2025-06-03' | 105
128   | 5                | '2025-06-04' | 20717
65    | 6                | '2025-06-05' | $${\color{red}5}$$

Now we do a GROUP BY POSTPROCESSING. Here the issue starts because GROUP BY is a time consuming
operation because the data is not already correctly pre-sorted by the scan.

> [!IMPORTANT]
> This is not the perfect input for the GROUP BY.

$\textsf{\color{red}{Reason: GROUP BY execution is slower if entries with the same key are not executed together.}}$  

> [!NOTE]
> In general, GROUP BY is more time consuming than a SCAN. 

> [!WARNING]
> The optimizer may decide not to use the zone map because it estimates that another access path or index is more efficient.

## References

* [Exasol Zone Maps documentation]([https://docs.exasol.com/db/latest/database_concepts/scripting/general_script_language.htm#TypesandValues](https://docs.exasol.com/db/latest/performance/zonemaps.htm))

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*







