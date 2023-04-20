# How to Split One Row Into Multiple

## Question
I want to create a VIEW to show multiple rows for each source row.
Example:
I have a table of events. I have to split each event longer than 1 day to many rows representing each day of this event.

Source table:
|event_name|	Start_time|	end_time|	duration|
|-|-|-|-|
event1|	01.07.2021|	03.07.2021|	3
event2|	05.07.2021|	06.07.2021|	2

With the expected result being:
|event_name|	Start_time|	duration|
|-|-|-|
event1|	01.07.2021|	1
event1|	02.07.2021|	1
event1|	03.07.2021|	1
event2|	05.07.2021|	1
event2|	06.07.2021|	1

## Answer
Something like this should work:  
```
with base(event_name,	Start_time,	end_time,	duration)  
as (  
SELECT 'event1',to_date('01.07.2021','DD.MM.YYYY'),to_date('03.07.2021','DD.MM.YYYY'),3 from dual union all  
SELECT 'event2',to_date('05.07.2021','DD.MM.YYYY'),to_date('06.07.2021','DD.MM.YYYY'),2 from dual  
),  
dim_date as (select to_date('20210101','YYYYMMDD') + (level-1) as dat from dual connect by level<=365)  
select * from base inner join dim_date on dat between start_time and end_time;
```

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 