# &quot;[p]query function: number of open result sets exceeds 250&quot; caught in script 
## Question

Why does the following error occur in Scripts and what does it mean:

'[p]query function: number of open resultsets exceeds 250" caught in script' 

## Answer

The error message : '*[p]query function: number of open resultsets exceeds 250" caught in script*' means that a variable is attempting to store more than 250 result sets of queries. You are only able to hold 250 result sets so that the script does not run out of memory. The number of simultaneously opened result sets inside a script execution is internally limited to 250.  
This means that if the recursion depth in the script query exceeds 250, the application logic must therefore be changed, for example, into a loop that iterates over the objects to be deleted.

Hence, we can say that, there is probably a variable which does not get re-initialized during a loop, so it holds all of the result sets within one variable, which gets looped over.

A solution of this would be to re-initialize the variable at the beginning of the loop so that it does not constantly store all of the query results.

### Example:

A basic example of this behavior can be found with the following queries:


```markup
create script queryscript(param1) returns table as
    exit(query( [[select :t from dual]] , {t=param1} ));
/

create script loopscript_query_local() as
    for run=1,500
    do
        res_local = {}
        result = query("execute script queryscript("..run..")")
        res_local[run] = result  --local holder
        output(run..": is OK, return value="..result[1][1])
    end
/

create script loopscript_query_global() as
    res_global = {}
    for run=1,500
    do
        result = query("execute script queryscript("..run..")")
        res_global[run] = result --global holder, to test the exception
        output(run..": is OK, return value="..result[1][1])
    end
/

execute script loopscript_query_local() with output; -- This will work because the variable is recreated on every iteration

execute script loopscript_query_global(); -- this will produce the same error because res_global is storing more than 250 result sets
```

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 