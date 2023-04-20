# Query Wrapper Tool Suggestion

## Question
I'd like to suggest a slight modification of the query-wrapper tool:

You are trying to fetch the job-id from the main-log table but without filtering on the script_name, this could lead to issues if you have several applications using the same logging table.
```
-- Step 2) retrieve max ELT_RUN_ID
local success, res = pquery( [[SELECT MAX( run_id ) FROM ::MAIN_LOG_TABLE]], {MAIN_LOG_TABLE = main_log_table} )
```
so would you please extend this to something like that:
```
-- Step 2) retrieve max ELT_RUN_ID
local success, res = pquery( [[SELECT MAX( run_id ) FROM ::MAIN_LOG_TABLE WHERE SCRIPT_NAME = ::SN]], {MAIN_LOG_TABLE = main_log_table, SN = script_name } )
```
## Answer
Exasol's transaction system will prevent this scenario, as the initial INSERT into the main log table write-locks that table until the transaction is ended through rollback or commit, which happens *after* the SELECT in question. (There is no auto-commit within a lua script)

That transaction system is also the main reason why the query wrapper goes through so much pain to collect log messages locally before actually inserting them into the detail log table.

Current implementation makes pretty sure that the generated RUN_ID is unique across any and all concurrent calls to the query_wrappper.

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 