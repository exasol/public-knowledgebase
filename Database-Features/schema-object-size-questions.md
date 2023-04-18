# Schemas Object Size Questions

## Question
We are building a SaaS solution, where we plan to put each customers data in separate schema. Over time this will hopefulle mount to a lot of schemas. 

In order to cover the bases I would love your take on the implications of this approach:
  1. Is there a limit - fixed or practical - on the number of schemas an instance can handle (10.000, 100.000, 1.000.000)?
  2. Is there an overhead per schema, that affect the resources needed in an instance?
  3. Is there a performance penalty due to the system tables growing large from a high amount of schemas, tables, columns, etc.?
  4. Other things to take into account?

I would expect that this approach, where the amount of date per customer is small, have implications on the data distribution rules once we go into production and establish a cluster setup, and I expect to get back to you once we get there.

## Answer
There is no limit in regards to the amount of objects in a database since Version 6.2. Objects are schemas, tables, views, functions, scripts. That said: there is no limit in amount of schemas.

But of course there is some overhead in regards to system table / metadata queries with an increasing amount of objects. I am not aware that this ever had a bigger impact on query performance.

To minimize the overhead on system table / metadata queries it is highly recommended to use selective filters for those. Some examples:

    Schema name filter for exa_schemas
    schema and table name filter for exa_dba_tables 
    schema and view filter for exa_dba_views
    ...

Our engine will be able to apply such filters deep in our engine to get optimal performance.