# Showing Impersonation Details in EXA_DBA_AUDIT_SQL 
## Background

Impersonation is a new feature in Exasol 6.1. It allows for switching to a different effective user during a session. Use this to impersonate another user identity. 

## Explanation

The new system privilege IMPERSONATE ANY USER has been granted to sys and to the DBA role. This allows sys respectively grantees of the DBA role to become any user without having to specify their password:


```"code-sql"
-- Example 1: sys is connected and becomes fred: 
IMPERSONATE fred;
```
Otherwise, the IMPERSONATION ON <user_name> privilege can be granted to a user that should be allowed to impersonate that other user.


```"code-sql"
-- Example 2: bob is allowed to impersonate sys 
GRANT IMPERSONATION ON sys TO bob; 
```
Using the IMPERSONATE command, users can change the effective user within their sessions:


```"code-sql"
-- Example 3: bob impersonates sys, so that he has sys' privileges 
SELECT current_user; -- shows BOB 
IMPERSONATE sys; 
SELECT current_user; -- shows SYS 
```
The following system tables contain information about impersonations:

* EXA_USER_SESSIONS, EXA_ALL_SESSIONS, EXA_DBA_SESSIONS:
	+ The column USER_NAME shows the user connected to the database; that is the user who opened the session.
	+ The column EFFECTIVE_USER shows the current effective user after impersonation. Queries are executed with the privileges of the effective user.
* EXA_DBA_AUDIT_IMPERSONATION:
	+ IMPERSONATOR: The user who impersonates (before executing the IMPERSONATE command).
	+ IMPERSONATEE: The new effective user (after executing IMPERSONATE).
	+ SESSION_ID, STMT_ID: The session id and statement id of the IMPERSONATE command withing this session.

Mind that EXA_DBA_AUDIT_... tables are only populated with data if auditing is enabled in the database settings in EXAoperation.

* EXA_DBA_AUDIT_SQL does not contain any information about the effective user that executed a SQL statement.
* EXA_DBA_AUDIT_SESSIONS shows only the user that opened the connection.

The following query adds an EFFECTIVE_USER column to the EXA_DBA_AUDIT_SQL. It shows for every query with whose user's privileges a query was executed:


```"code-sql"
with impersonations as
(
  select stmt_id + 1 as first_stmt_id, lead(stmt_id, 1, 999999999999) 
         over (partition by session_id order by stmt_id ) as last_stmt_id,
         impersonatee as effective_user, session_id
  from exa_dba_audit_impersonation  
)  
select nvl(ai.effective_user, se.user_name) effective_user, sq.* 
from  exa_dba_audit_sql sq
join  exa_dba_audit_sessions se
  on  sq.session_id = se.session_id
left join  impersonations    ai
       on sq.session_id = ai.session_id 
      and sq.stmt_id between ai.first_stmt_id and ai.last_stmt_id
where sq.session_id = current_session
order by stmt_id;
```
## Additional References

See here

* for a video that explains impersonation: <https://www.youtube.com/watch?v=h2Mrbd0r67k>
* for documentation <https://docs.exasol.com/sql/impersonate.htm>
