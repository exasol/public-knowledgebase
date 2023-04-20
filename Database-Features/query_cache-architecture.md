# QUERY_CACHE Architecture

## Question
I noticed in a few areas of the Performance Management training, for the purposes of learning and understanding the Profiling and Performance impacts, we were instructed to turn off the QUERY_CACHE setting for our session.

I am trying to understand the Query Cache setting from the architectural perspective. Can you confirm my depictions below and that I am paraphrasing the concept correctly?

If QUERY_CACHE is ON, then when a query is run, data blocks are loaded into memory, but additionally the specific data set retrieved by the query is also put into a special 'cache' separate from the native memory for future runs of the same query.

If QUERY_CACHE is OFF, then when a query is run, data blocks are still loaded into memory, but additional runs of the same query will need to re-process the result set from the data blocks in memory, and nothing will be stored in the CPU cache.

## Answer
Just to explain that again first: We turn off the query cache in the Performance Management course because we want to see the real runtime of statements when they come repeatedly. The default setting is ON and that's a good thing in a production environment.

Your understanding is largely correct. Only that there's no CPU caching directly involved from the database layer. The query cache is a small part of the memory allocated for the cluster nodes with the DB RAM setting upon database configuration.

If a query runs for the first time, it has to load data blocks into memory and process them there. Then a result set is produced. This result set is then stored in the query cache - if it is sufficiently small and the query is deterministic, delivering the same result set for every subsequent call. Going forward, that result set is just shown again from the query cache for every call of that same statement, without having to access and process data blocks again - neither from memory nor from disk. Should the table content be modified by DML afterwards, the query cache is automatically invalidated and data blocks have to be accessed again once for those queries.

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 