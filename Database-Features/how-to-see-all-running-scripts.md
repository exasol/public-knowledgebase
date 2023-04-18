# How to See All Currently Running Scripts

## Question
Currently I am writing a python script to start off a script in Exasol using the Exasol Websocket (in order to fill in the lack of a scheduler in Exasol atm). 

However, I would like to get some conditional logic involed saying please do not start the script when it is already running. Problem is that I cannot really find a system table that shows all currently running scripts. I can find the currently running sql statements, but the script executes a bunch of different sql statements (which are also variable, so i cannot just check if any of these statements is running). 

Is there a way to check if anything in the scope of the script is currently running in Exasol?? The script that I want to execute from my python script is written in LUA. 

## Answer
We had to add some logging of the sessions that start off these scripts. When the session is stopped due to connection issues the STATUS is not updated in the job log. Hence we also now check to see if the session of the last script is still alive when the status is still running. Quite helpfull for situations where i.e. the database is shut down at night for cost reasons. (then this situation occurs a lot!). In the code example you can see what we do to check. To register the session ID that runs the script we added the session id to the job_detail log that registers the job nr .... in line 254 of the query wrapper. 
```
  -- row 247 of the query wrapper script
      local success, res = pquery( [[SELECT MAX( run_id ) FROM ::MAIN_LOG_TABLE]], {MAIN_LOG_TABLE = main_log_table} )
        if not success then
            self:log( 'WARNING', 'Failed to retrieve job id: [' .. res.error_code .. '] ' .. res.error_message )
            pquery( [[ROLLBACK]] )
            return nil
        end
        self.run_id = res[1][1]
        self:log( 'INFO', 'Job nr. ' .. self.run_id .. ' registered session id =' .. self.session_id )
```
```
CREATE LUA SCRIPT "XXX" () RETURNS ROWCOUNT AS
import('etl.query_wrapper_test','qw')

wrapper = qw.new('etl.job_log', 'etl.job_details', exa.meta.script_name)

suc, res  = wrapper:query([[SELECT 
								jl.RUN_ID,
								SUBSTRING(LOG_MESSAGE, LOCATE('=', LOG_MESSAGE)+1) prev_session_id,
								CASE WHEN jl2.status = 'STARTED...' THEN TRUE 
								ELSE FALSE 
								END script_is_running, -- IF FALSE THEN SCRIPT can GO ahead
								CASE WHEN edas.SESSION_ID IS NULL THEN FALSE
								ELSE TRUE
								END session_is_active -- IF FALSE THEN SCRIPT can GO ahead
							from							
								(SELECT 
									max(run_id) run_id 
								FROM etl.JOB_LOG jl 
									WHERE SCRIPT_NAME = ']] ..exa.meta.script_name.. [[' AND RUN_ID < (SELECT MAX(RUN_ID) FROM etl.JOB_LOG 
									WHERE SCRIPT_NAME = ']] ..exa.meta.script_name.. [[')) jl
							LEFT JOIN etl.JOB_DETAILS jd ON jd.RUN_ID = jl.RUN_ID AND REGEXP_INSTR(jd.LOG_MESSAGE, 'registered session id =[0-9]{19}') <> 0
							LEFT JOIN etl.JOB_LOG jl2 ON jl.RUN_ID = jl2.RUN_ID
							LEFT JOIN EXA_STATISTICS.EXA_DBA_AUDIT_SESSIONS edas ON TO_CHAR(edas.SESSION_ID) = SUBSTRING(LOG_MESSAGE, LOCATE('=', LOG_MESSAGE)+1); ]])
	
							
if res[1][3] == false then 
	goto continue
elseif res[1][4] == false then
	goto continue
else 
	wrapper:log('WRAP_LOG', exa.meta.script_name..' FAILURE: PREVIOUS SCRIPT STILL RUNNING')
	goto exit
end -- followed by actual script 
```