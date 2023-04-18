# Refresh All Virtual Schemas Script

One question in the recent Ask-Me-Anything (AMA) session on virtual schemas the question was asked, when virtual schemas objects (available tables etc.) are refreshed and how to refresh them without issuing the "ALTER VIRTUAL SCHEMA x REFRESH" statement manually.
- First answer: The virtual schema objects are not automatically refreshed, you have to use the ALTER VIRTUAL SCHEMA command 
- Second answer: I have crafted a simple LUA script which does that for you for all schemas. Adapt the schema where this script should be stored (and/or name the script as you like), execute the SQL and you can then update all objects by just calling the procedure.
```
    CREATE LUA SCRIPT "<SCRIPT SCHEMA>.TOOLS_UPDATE_VIRTUAL_SCHEMAS" () RETURNS TABLE AS
/******************************************************************************
* Script to refresh the virtual schemas, as an automatism to recognize 
 * changes on tables is missing in Exasol.
*  
 * Return value: Number of objects (may be 0)
* 
 * Execute:
* EXECUTE SCRIPT <SCRIPT SCHEMA>.TOOLS_UPDATE_VIRTUAL_SCHEMAS
* 
 * Execute with debugging:
* EXECUTE SCRIPT <SCRIPT SCHEMA>.TOOLS_UPDATE_VIRTUAL_SCHEMAS WITH OUTPUT;
* 
 * Author: <Your name here> (10.06.2021)
* 
 * History (latest first):
* yyyy-mm-dd (who): Description
****************************************************************************** */
do
       ---------------------------------------------------------------------------
       -- Constants
       ---------------------------------------------------------------------------
       
       -- Identify objects (schemas)
       local SQL_GET_OBJECTS = [[
             SELECT 
                     BASE.SCHEMA_NAME AS OBJECT_SCHEMA
             FROM
                    SYS.EXA_ALL_VIRTUAL_SCHEMAS BASE              
             ORDER BY
                    1
       ]]
       
       local SQL_REFRESH = [[
             ALTER VIRTUAL SCHEMA %s REFRESH
       ]]
       
       ---------------------------------------------------------------------------
       -- Functions
       ---------------------------------------------------------------------------
       
       -- Helper function for a kind of try/catch (pcall) on query execution
       function exec_query(exec_sql)
             return query(exec_sql)
       end
       
       ---------------------------------------------------------------------------
       -- Variables
       ---------------------------------------------------------------------------
       local query_results = {}
       local object_name = ''
       local success_count = 0
       local result_table = {}
       
       ---------------------------------------------------------------------------
       -- Main
       ---------------------------------------------------------------------------
       
       -- Get virtual schemas
       query_results = query(SQL_GET_OBJECTS)
       if #query_results > 0 then
       
             -- For each object, call refresh
             for row_counter = 1, #query_results do
                    object_name = query_results[row_counter]['OBJECT_SCHEMA']
                    output(string.format('%s: Refreshing', object_name))
                    
                    -- Execute SQL in a try/catch kind of way
                    local success, results=pcall(exec_query, string.format(SQL_REFRESH, object_name)) 
                    if success then
                           success_count = success_count + 1
                    else
                           -- There was a problem, add object to results table as "failed"
                           result_table[#result_table + 1] = {'Failed', string.format('%s', object_name)}
                    end                 
             end
       end
       
       -- Add as first row the number of successfully updated objects
       table.insert(result_table, 1, {'Successful', string.format('%s objects', success_count)})
       
       exit(result_table, 'TYPE varchar(15), RESULTS varchar(4000)')
end
```
