# How to get a profiling data for Exasol support 
## Background

Query behavior is unexpected

Sometimes Exasol exhibits unexpected behavior when executing queries. Analyzing "this is slow" in support is impossible without additional information. The single foremost information we need is profiling data for the query in question, if possible also profiling data of a similar query that gives better results.

## How to get a profiling data for Exasol support?

Execute the following steps:

## *Step 1*

Obtain the SQL text of the query in question

## *Step 2*

Open a new database connection, typically using EXAplus

## *Step 3*

Execute the following:


```"noformat
  set autocommit on;   
  alter session set profile='on';   <your query here>;   
  alter session set profile='off';   
  alter session set NLS_NUMERIC_CHARACTERS='.,';   
  alter session set NLS_TIMESTAMP_FORMAT='YYYY-MM-DD HH:MI:SS.ff3';   
  flush statistics;      
  export (select * from EXA_STATISTICS.EXA_USER_PROFILE_LAST_DAY where session_id = current_session)   
  into LOCAL CSV   FILE 'profile_output.csv'; 
```
## *Step 4*

Attach the generated CSV file to your support ticket.

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 