# Retrieving DB User's Last Login Time and Last Session Details

## Question

How to retrieve the last login time or last session's details of a DB user?
Possible use case: Identify database user accounts that have not been actively used recently.

## Answer

The `EXA_DBA_SESSIONS_LAST_DAY` view could be used to get information about user activity over the past 24 hours. 
However, to analyze data beyond this timeframe, you need to enable auditing (if it is not already activated). You can find out more about auditing and how to switch it on in the article below.

With auditing enabled, you can use `EXA_DBA_AUDIT_SESSIONS` to track all user activities, including the last session and last login timestamp. For example, the following query will display the last session for each DB user:

```sql
-- Select last user session from audit
select * from  
(select a.*,
row_number() over (partition by user_name order by login_time desc) as rn
from EXA_DBA_AUDIT_SESSIONS a
)
where rn =1
order by user_name;
```

## Additional References
 
[Exasol DB: Database Concepts &gt; Auditing](https://docs.exasol.com/db/latest/database_concepts/auditing.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
