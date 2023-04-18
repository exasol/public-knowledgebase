# Cast Ignored When Querying Virtual Schema

## Question
I'm running two select statements on virtual schema's. Since they're joined in a union and don't all have the same columns, I need a column with '' or NULL values. This results in an error: SQL Error [0A000]: Feature not supported: datatypes are not compatible for Union (Session: 1715323572262273024)

The '' or NULL column appears to be a boolean. 

Changing this to the desired data type using: CAST( '' AS VARCHAR(18)) results in exactly the same error.

Running the statement separately shows that the CAST is ignored. It appears to happen when querying on virtual schemas. Doing the same on regular schema's or without referring to objects does not result in the CAST being ignored.

Is there a way to make my query work without creating additional objects?

## Answer
I could reproduce the error with an Exasol virtual schema dialect. For this dialect I found the following two potential workarounds:  

Workaround One:
```
ALTER VIRTUAL SCHEMA VS_20_HDA_WINLINE_CCVBI SET EXCLUDED_CAPABILITIES = 'LITERAL_NULL'; 
```

Workaround Two:
```
select 
	C_GLACCOUNTNO 		as General_ledger_account_code  
	, C_GLACCOUNTNAME 	as General_ledger_account  
	, (SELECT CAST('' AS VARCHAR(18)))  
	, 'Winline' 		as Source_application  
	,1 AS TEST1  
	,CAST(1 AS VARCHAR(10)) CASTTEST1  
	,'1' AS TEST2
	,CAST('1' AS VARCHAR(10)) CASTTEST1  
	,11 AS TEST3  
	,CAST(11 AS VARCHAR(10)) CASTTEST3  
	,TRUE AS TEST4  
	,CAST(TRUE AS VARCHAR(10)) CASTTEST4  
from  
	VS_20_HDA_WINLINE_CCVBI.V_CWLGLACCOUNT_ACTUAL
```
 


Solving this issue is not trivial. As you can see in the pushdown results of EXPLAIN VIRTUAL, the Exasol compiler removes the cast in the query. This is an optimization that happens quite early and before the handling of virtual schemas. For queries without virtual schemas this reduces the execution time and is no issue. In the virtual schema scenario, the pushdown contains a null_literal without datatype. The remote database of the virtual schema then returns a NULL with an arbitrary JDBC Type. This can vary based on the dialect. For the Exasol virtual schema dialect this is Boolean. In theory, the Exasol compiler can reinsert the cast to the desired type. But while this is possible in your scenario, it is not possible for complex expressions. For that, the compiler needs exact types from the JDBC driver.

I hope the workarounds are sufficient for the time being until we have this feature in the JDBC driver.
