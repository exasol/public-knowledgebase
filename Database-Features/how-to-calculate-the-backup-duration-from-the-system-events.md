# How to calculate the backup duration from the system events table 
## Background

Details about backups are stored in the table EXA_SYSTEM_EVENTS. This table shows the start and stop times of backups, in addition to restarts, fail safety, and more. We can query this table to find the duration of a backup.

## Calculate the backup duration from the system events table

You can use the below query to calculate the duration of backups.  


```"code
with intermediate as
(
    select s.*
    , lead(event_type) over (order by measure_time)  end_event
    , lead(measure_time) over (order by measure_time)  end_time
from
    exa_system_events s
where
    event_type like 'BACKUP%'
)
select
    i.*
    , cast(trunc(measure_time, 'DD') as date) start_date
    , cast(round(minutes_between(end_time, measure_time)/60, 2) as decimal(10,2)) backup_duration
from
    intermediate i
where
    event_type = 'BACKUP_START' and end_event not like '%START'
    and measure_time > trunc(now(), 'YYYY')
order by
    measure_time desc;
```
## Additional References

<https://exasol.my.site.com/s/article/Analyzing-disk-I-O-and-concurrency-based-on-last-day-data>

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 