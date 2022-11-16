# LUA Scripts Exception Handling

## Question
We want to migrate to Apache Airflow. Airflow invokes existing lua scripts via ExasolOperator. 

The problem is that the existing lua scripts surpress all errors via pcall and Airflow will mark failed lua script execution as success.

My solution to this problem is to throw error() in case there is an error within the lua script. I am not sure about the usage of error() within lua scripts. The error() function is documented as part of functions not scripts https://docs.exasol.com/database_concepts/scripting/general_script_language.htm .

Motivation for using error() in a lua script: At each step the results of a pcall are logged. If there is a critical error, that error should be logged as well and the script should terminate with an error message using the error() function. The Apache ExasolOperator will mark the Task as "Failed", when the lua function exited with error() and also logs a meaningful error message if it was provided as an argument to error().

The following example script does that.
```
CREATE OR REPLACE LUA SCRIPT HANDLE_ERROR() RETURNS TABLE AS  
RESULT_VALUE={}  
RESULT_VALUE[1]={1,"OK", 'initialized'}  
  
-- step 1 and following steps  
-- do something and log the results in RESULT_VALUE  
-- ...

-- step X that fails   
success, res = pquery([[SELECT 0/0]])

if not success then  
			-- do something, like log the result  
			-- then throw an error 
			error(res.error_message)  
		else  
			RESULT_VALUE[#RESULT_VALUE+1]={#RESULT_VALUE+1,"OK","step X".." executed"}  
end  
-- return the results of each step  
exit(RESULT_VALUE,"STEP DECIMAL(10,0), STATUS VARCHAR(50) ,COMMENT_RESULT VARCHAR(50000)");
```
 When executed the script produces the error: SQL-Error [43000]: "data exception - division by zero" - this is the expected result.

If step x is not failing (for instance SELECT 0 / 1) then the script returns a table:

|   |   |                 |  
| - | -- | --------------- |  
| 1 | OK | initialized     |  
| 2 | OK | step X executed |

 

Questions:  
- Are the any negative consequences of using error() within a lua script? Like rollbacks that only happen when invoking error(), etc.
- Are there any differences between using error() within a lua function and error() within a lua script?


## Answer
- There are no negative consequences using error()  
    - ROLLBACK or COMMIT is not triggered by error() function, you can define a behavior for the non-successful query execution yourself within the script
        - E.g. query([[rollback]]) in line 13  
    - If you do not specify an error behavior in the script, you can use rollbacks or commits on the session used  
    - If session terminates, a rollback is automatically performed  
    - *Please note* if autocommit is switched to on, the database will perform a commit after script termination independent of a successful execution (same behavior as for any other statement)  
- error() function behavior is independent from being executed in a script directly or encapsulated in a function within a script  
    - I think there is some "try / catch" logic possible within Lua (pcall), but I have rarely seen this in use within Exasol procedure scripts
