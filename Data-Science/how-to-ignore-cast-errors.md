# How to Ignore Cast Errors

## Question
I was trying to cast a string to number but got an error since the field contained some non-numeric characters or where null.
I had to extract the integer through regular expression to get it to work. Is there any other way to use regular cast and just ignore all unsucceful tries? 

>TO_NUMBER(REGEXP_SUBSTR(strNumber,'[0-9]*'))
## Answer
You might want to give a try to our family of IS_% functions:
```
with  
to_clean(col1) as(  
	SELECT  
		*  
	from  
		values ('1'), ('1a'), ('2.5'), ('3,6')  
)  
select  
	tc.col1  
	, case  
		when is_number(tc.col1) then to_number(tc.col1)  
	end as col1_num  
from  
	to_clean tc  
;  
/*  

COL1|COL1_NUM|  
----+--------+  
1   |     1.0|  
1a  |        |  
2.5 |     2.5|   
3,6 |        |  
*/  

```