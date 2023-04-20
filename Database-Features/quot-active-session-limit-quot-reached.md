# &quot;Active Session Limit&quot; Reached 
## Problem

Exasol supports 100 active slots by default in use by the database. Exasol's Session Management is described in detail in [our documentation](https://docs.exasol.com/database_concepts/session_management.htm). 

Due to this concept, there could be the case where all of these slots are in use by sessions, forcing additional incoming queries to wait.  

## Diagnosis

When all of the active slots are in use, you will see the following in the Exaoperation logs:


```markup
Limit of active sessions has been reached.
```
There are also messages that describe when you are getting close to this limit, however these messages are simply warnings and do not necessarily require any action:


```markup
Query queue limit of active sessions nearly reached,  running: 
<<active_sessions>> of 100 (+ <<blocked_sessions>> WAIT FOR COMMIT) are in use. 
```
## Explanation

A session occupies an active slot if it meets one of the following criteria:

* Performing query execution
* Has open transactions
* Has open prepared statement
* Has open resultset
* Has open sub-connection

This "active session" is set to 100 for performance reasons. Since all queries share the cluster resources, the more concurrent queries are running, the fewer resources are available for each session. When this active slot limit is reached, it does not mean users cannot ever login or run queries.

Rather, all future active sessions will be "queued" and must temporarily wait until they are able to occupy an active slot. Once an active session is no longer "active" (for example, disconnects, query execution finished), then it will give up its slot and a new session can occupy it. In rare cases, where none of the sessions give up the slot, or there are so many sessions waiting that there is a large queue, you may need to take action.

## Recommendation

## 1. Sporadic Messages

If this message only appears sporadically, there is not an immediate need to take action.

However, it would be wise to begin reviewing why the sessions are staying active for so long. It is more likely that sessions occupy an active slot accidentally, particularly if sessions have long-running transactions, but are actually idle.

### 1.1. Find idle sessions with open transactions

We recommend to use [this query](https://exasol.my.site.com/s/article/How-to-determine-idle-sessions-with-open-transactions-Except-Snapshot-Executions?language=en_US) to find idle sessions with open transactions.

### 1.2. Investigate resultsets or prepared statements which are open

In addition, you should investigate if sessions or clients are keeping resultsets or prepared statements open unnecessarily.

## 2. Constant Messages/Not able to Login

### 2.1.  JDBC parameter "superconnection=1"

If the message appears constantly and you are not able to login to check what is happening, you can use a special driver parameter to login as SYS. In your SQL client, you can set the JDBC parameter "superconnection=1", which will enable you to login as SYS, even if the active session limit is reached and your login is delayed.

### 2.2. Kill sessions

With this parameter, you can run queries on EXA_DBA_SESSIONS (such as the one mentioned above) to kill sessions which need to be killed.

 **This process is preferred over restarting the database because it will not affect any of the data that is in RAM.**

To check which sessions are running queries:


```markup
SELECT COUNT(*) FROM EXA_DBA_SESSIONS WHERE STATUS = 'EXECUTE SQL';
```
If this number is significantly under 100, then some of the other sessions are occupying an active slot for one of the other above mentioned reasons. You may try to kill all sessions, or just the idle sessions. To easily kill these sessions, you can use this query:


```markup
-- Will kill every session
SELECT 'KILL SESSION ' || SESSION_ID || ';' STMT FROM EXA_DBA_SESSIONS WHERE SESSION_ID NOT IN (4,CURRENT_SESSION);

-- Will kill only idle sessions
SELECT 'KILL SESSION ' || SESSION_ID || ';' STMT FROM EXA_DBA_SESSIONS WHERE SESSION_ID NOT IN (4,CURRENT_SESSION) AND STATUS = 'IDLE';
```
### 2.3. Analyze the problem

Once the situation is under control, you should investigate your processes and see if sessions are unnecessarily active. It is important to evaluate why the system reaches this limit. Such questions could help answer these questions:

* Are there hardware issues (Slow HDD Read/Network issues) causing a bottleneck?
* Why are queries running for a long time?
* Is this increase a recent change? What has changed recently?

If needed, Exasol Support can also assist in explaining which sessions were active and for which reasons. 

## 3. Why not just increase the number of active sessions?

As already mentioned too many active sessions are often a symptom for a different problem (e.g. erroneous clients), so it is important to find and fix the root cause of the problem.  
Furthermore, more active sessions, does not mean more performance or throughput. This depends highly on your workload and resource utilization.   
For example: If 100 queries in parallel use 100% of the CPU resources it will not help to increase the number of active sessions. The only effect will be that each of the 200 queries in parallel takes longer to compute, but the overall throughput is the same. This is even more critical when your workload is memory bound, because more parallel queries could lead to out of memory scenarios and an overall slowdown.

## Additional References

* [Identify idle sessions with open transactions](https://exasol.my.site.com/s/article/How-to-determine-idle-sessions-with-open-transactions-Except-Snapshot-Executions?language=en_US)
* [Session Management](https://docs.exasol.com/database_concepts/session_management.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 