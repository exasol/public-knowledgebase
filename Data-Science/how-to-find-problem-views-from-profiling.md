# How to find Problem Views from Profiling

## Question

I have a very complex data model with many layers of views.
In query profiling I identified a problematic join between two tables.

How do I find out which view(s) lead to the inclusion of those tables, so I can try and fix things?


## Answer

### Example Setup

As is often the case with dependency tracking, we require a top-level view to start our search.
In the following **example**, we will use the view `CUSTOMER_STATS_RLS.F_MONITOR` as entry point.

Selecting from the view will provide a profile which includes the following pipeline:

|PART_ID|PART_NAME|PART_INFO|OBJECT_SCHEMA|OBJECT_NAME|
|---|---|---|---|---|
|7|PIPE SCAN|on REPLICATED table|CDP|DATABASE_JI|
|8|PIPE JOIN|(null)|CDP|ISSUES|
|9|PIPE JOIN|on REPLICATED table|CDP|ISSUESTATI|
|10|PIPE FILTER|(null)|(null)|(null)|
|11|PIPE INDEX OUTER JOIN|on REPLICATED table|CDP|ISSUEVERSIONS|
|12|PIPE PREFERENCE PREFILTER|(null)|(null)|(null)|
|13|PIPE FULL PREFETCH|PIPE BUFFER|CDP|ISSUES|

Unfortunately for us, profiling shows the final execution plan, which contains tables only, the view layer has
been stripped away.

Let's say we are interested how `ISSUES` is used twice, and how it relates to `DATABASE_JI`.

### Analysis Query

We will use the following query (template) to perform dependency analysis:
```sql
with k1 as (
    select
        sys_connect_by_path(object_schema||'.'||object_name, ' > ') as pth,
        referenced_object_schema,
        referenced_object_name
    from sys.exa_all_dependencies
    
    connect by object_schema = prior referenced_object_schema
           and object_name   = prior referenced_object_name
   
    -- this is the view you examine
    START WITH object_schema   = 'CUSTOMER_STATS_RLS'
           and object_name     = 'F_MONITOR'
)
select distinct pth
from k1
-- this is the dependency you want to find / saw in profiling
where referenced_object_schema = 'CDP'
  and referenced_object_name   = 'DATABASE_JI'
order by pth;
```

**Notes:**
- As view security allows to hide implementations and dependencies from users, `EXA_ALL_DEPENDENCIES` might not return
  the full picture. In these cases you may have to use the `EXA_DBA_DEPENDENCIES` system table instead, which requires
  the `SELECT ANY DICTIONARY` system privilege.
- On systems with a high object count, the inner select may be slow. In these cases, adding a `WHERE` condition before
  the `CONNECT BY` can speed things up by filtering on known schema names.
- The dependency table does only include views that are currently in a valid state -- as we just executed a query using the view hierarchy,
  this should not be a problem here.

### Output Evaluation.

When we execute the query above for both `DATABASE_JI` and `ISSUES`, we get the following two results, showing all possible
paths from the main view down to each view accessing the object we queried:

For CDP.DATABASE_JI:
```text
 > CUSTOMER_STATS_RLS.F_MONITOR > CUSTOMER_STATS_RLS.INT_DATABASE_TIMELINE > CUSTOMER_STATS_RLS.DIM_DATABASE > CUSTOMER_STATS_2016.H_V_DATABASE > CUSTOMER_STATS_2016.jira_H_V_DATABASE
```

For CDP.ISSUES:
```text
 > CUSTOMER_STATS_RLS.F_MONITOR > CUSTOMER_STATS_RLS.INT_DATABASE_TIMELINE > CUSTOMER_STATS_RLS.DIM_DATABASE > CUSTOMER_STATS_2016.H_V_DATABASE > CUSTOMER_STATS_2016.jira_H_V_DATABASE
 > CUSTOMER_STATS_RLS.F_MONITOR > CUSTOMER_STATS_RLS.INT_DATABASE_TIMELINE > CUSTOMER_STATS_RLS.DIM_DATABASE > CUSTOMER_STATS_2016.H_V_DATABASE > CUSTOMER_STATS_2016.jira_H_V_DATABASE > CDP.ISSUEVERSIONS 
```

**Evaluation:**
- Based on the common prefix of all access paths, the view `CUSTOMER_STATS_2016.jira_H_V_DATABASE` will be of interest.
- We can see that `ISSUES` is used in two different places.
- Together with the fact that our query profile above does not include any `tmp_subselect` elements, we can deduce that
  the view `CDP.ISSUEVERSIONS` is "simple" and gets eliminated, embedding its logic into the parent view during execution.

Extracting the view text for `jira_H_V_DATABASE` using the `EXA_ALL_VIEWS` system table, we find the following part, which
indeed answers our initial question:

```sql
 from
  CDP.DATABASE_JI D
 
  join CDP.ISSUES I
   on I.ISSU_ID = D.DABA_ISSU_ID

  join CDP.ISSUESTATI SS
   on SS.ISTA_ID = I.ISSU_ISTA_ID

  left join CDP.ISSUEVERSIONS V
   on V.IVER_ISSU_ID = D.DABA_ISSU_ID
```

**Notes:**
- The same technique can be applied to identify views generating `tmp_subselect` elements. Just identify the pipeline
  inserting / aggregating *into* that subselect, and pick a few tables from its SCAN and JOIN entries.
- The example above does not contain any actual problems. It was simply picked to illustrate the process.
- While the example is built to track down *TABLE* usage, the analysis query will also work for *VIEWS*, *FUNCTIONS* and
  (non-procedure) *SCRIPTS*.

## Additional References

1. User Manual: [Profiling](https://docs.exasol.com/db/latest/database_concepts/profiling.htm)
1. User Manual: [EXA_DBA_DEPENDENCIES](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_dba_dependencies.htm)


