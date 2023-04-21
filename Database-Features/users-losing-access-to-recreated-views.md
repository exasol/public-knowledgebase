# Users Losing Access to Re-Created Views

## Question
I created a role on my database for reporting purposes. 

> CREATE ROLE REPORTING;

Assigned users can select on some views from our access layer. For example:

> GRANT SELECT ON ACCESSLAYER.DIM_CUSTOMERS TO REPORTING; 

However, after some time they lose the right to see/select on particular views.
I have no idea why this is the case. Do you guys have any ideas how to solve this problem?

## Answer
When you re-create a view existing object privileges are dropped.

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 