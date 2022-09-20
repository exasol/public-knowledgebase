# Pagination 
## Background

## What is pagination?

Many times a frontend enters the challenge of presenting a very large result set to its user. A choice then has to be made between trying to do exactly that – load and display all data at once – and risking to run out of memory, taking "forever" to do so or overwhelming the unsuspecting user.

Usually, this problem is solved by implementing a technique called **pagination**: The large result set is arbitrarily split into multiple segments, usually equally-sized based on row numbers. The client then displays only one of those pages at a time, giving the user control over navigation between those pages.

## Where is the problem?

The next challenge here turns up to be data management: Is this simply a display issue where the frontend can easily keep all data hidden in the background, or does pagination have to be pushed even further down to the data source? And how will the data source be able to handle this?

## Solutions

## 1- Pagination for display only

This is the easiest solution when the frontend is able to keep the complete data set in memory (or other direct access). The frontend fetches all data from the data source, copies it into a local cache and uses that as a data source for pagination.  
This **requires** that the frontend can handle the **full amount of data**.

## 2 - Pagination for memory footprint

The next step in pagination is when the frontend is not able to keep the full result set locally. However, when the frontend is able to keep a **persistent database connection**, standard driver capabilities can be used to just keep the result set open on the database side and fetch data on demand. Exasol drivers all support scrolling, ie. the client can jump to arbitrary row positions for data retrievals. However, please note that network transfer is optimized for fixed block-size forward reading.

## 3 - Pagination for non-persistent clients

Where things get really complicated is when the frontend is not able to keep a persistent database connection. Typically this occurs with **web-based** applications where every user-request (including page navigation) is handled by a different application-side process. In this case, pagination must be implemented on the database side and triggered by the application. Multiple approaches exist for this:

### 3.1 - Using LIMIT

The simplest solution for the application developer is to use the LIMIT SQL feature: Appending LIMIT <count>,<offset> at the end of the query will only send the defined slice of data to the client.  
**Drawbacks:**

* Without a well-defined ORDER BY clause, the result of LIMIT may change between executions, resulting in inconsistent data display for the user. ORDER BY however is a costly operation.
* On the database side, each query arrives through a separate connection (= session = transaction) and will have to be calculated independently. For heavy analysis, this will cause the undesired effect that each page navigation will spend roughly the **same amount of time** as the initial request. To address that issue, Exasol 5.0 introduced an optional feature called **query cache**: This allows the database to calculate the full result (without limit) on the first invocation, put the result into a local cache and then answer subsequent requests from that cache. However, the cache size is limited and the cache is also transactional; see next point
* When base data changes, new connections are required to receive updated data. This might cause inconsistencies in data display or recalculation for the query cache.

### 3.2 - Using cache tables

To avoid the problems inherent to the LIMIT solution, the application can decide to create intermediate tables to get consistent data. In this case, we recommend adding a row number column for pagination purposes (do not use ROWNUM!). The row number column should be created using the analytical function ROW_NUMBER().  
**Drawbacks:**

* Analytical functions are expensive.
* A typical assumption in pagination is that most users navigate through the first few pages only. Thus, creating a table with the full result set might seem overkill.
* As we are in the scenario where each request is sent independently, the application probably has no way to clean up those cache tables. An asynchronous cleanup process has to be added.
* Names of the cache tables must be created in a unique way to avoid conflicts.
* As the tables need to be accessed by different sessions, they must be committed – requiring initial commit time and additional disk space.

### 3.3 - Adding middleware

The best solution in terms of user experience would be to place some kind of application server between the non-persistent (web-)frontend and the database. The middleware can then use scenario (2) above to provide consistent data in a timely manner. All it has to do is receive client requests, match them against previous requests and deliver data. Add some timeout to release (probably) unused result sets and you are set.  
**Drawbacks:**

* Development cost
* Additional component in IT landscape
* Keeping open large result sets will use up TEMP_DB_RAM, which will reduce the overall RAM available for the database. Old result sets can be swapped out to disk, however.

More logic can be added to reduce TEMP usage and calculation times:  
Invent 'super-pages' to calculate only parts of the result set – when they are required (or asynchronously when the user is getting close to the next super-page). As long as the middleware stays within the same transaction, the consistency aspect of (3.1) is no longer an issue.

