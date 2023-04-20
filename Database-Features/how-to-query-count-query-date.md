# How to Get a Query Count and Query Date

## Question
To evaluate which tables can be decommissioned from our Schema, we'd like to identify how many times the tables were queried and when was the last query date. 

I have looked at Satistical System Tables but was unable to find which command to generate below output: 
|TABLE NAME|    	QUERY_COUNT| 	LAST_QUERY_DATE|
|-|-|-|
CUSTOMER_PROFILES|  	300| 	11-08-2021
POC_PROFILES| 	2 |	14-03-2019| 
EXCHANGE_RATES_DECOM| 	10| 	01-01-2018 

Is it possible to get such output?  

## Answer
I´d go for the exa_dba_audit_sql in order to get the output table you provided - I´m not aware of any provided EXA_STATISTICS-table that would cater to this level of granularity.

Only "problem" with the exa_dba_audit_sql is: 
- you´d have to have it activated ( which is a good thing to have in any case ) and
- you´d have to parse the SQL_TEXT column for your TABLE_NAMEs - other than that it would be count(*) for the QUERY_COUNT ( executions , not unique queries ) and max(START_TIME) for the LAST_QUERY_DATE.

``` 
select  
table_name as TABLE_NAME,count(*) as QUERY_COUNT,CAST(max(start_time) as DATE) as LAST_QUERY_DATE  
 from exa_dba_audit_sql a inner join exa_dba_tables b on INSTR(upper(SQL_TEXT),b.table_name)>0  
 where start_time>=CURRENT_DATE - 365  
group by table_name  
;
```

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 