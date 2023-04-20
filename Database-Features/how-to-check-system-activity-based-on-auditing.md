# How to check System Activity based on Auditing 
## Background

Sometimes, you may want to look at exactly which queries were running at a specific point in time in the past. If this is the case, you can use the below query to show running queries at a moment in time. 

## Prerequisites

* Auditing must be enabled.

## How to check system activity

Use the following query to do this. Don't forget to insert the timestamp that you are looking for in the first CTE!


```markup
-- Replace the timestamp below with the timestamp you are interested in
with target_time as
        (select timestamp'2020-04-14 10:45:10.237' ts from dual
), recent_sessions as 
        (select * from EXA_STATISTICS.EXA_DBA_AUDIT_SESSIONS 
         where login_time > (select max(measure_time) from EXA_STATISTICS.EXA_SYSTEM_EVENTS where event_type='STARTUP')
), logged_in_sessions as 
        (select * from recent_sessions
         where (select min(ts) from target_time) between login_time and coalesce(logout_time, current_timestamp)
), running_queries as 
        (select * from EXA_STATISTICS.EXA_DBA_AUDIT_SQL
         where (select min(ts) from target_time) between start_time and stop_time
), active_sessions as
        (select L.login_time, L.logout_time, L.user_name,L.client,L.driver,L.encrypted,L.host,L.os_user,L.os_name, 
                S.* 
        from logged_in_sessions L left join running_queries S on (L.session_id=S.session_id)
)
select * from active_sessions;
```
## Additional References

* <https://docs.exasol.com/database_concepts/auditing.htm>

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 