# Analyzing disk I/O and concurrency based on *_last_day data 
## Background

System performance data about disk I/O and concurrency is sought. 

## How to analyze disk I/O and concurrency using *_last_day table data

## Step 1

### Checking "$EXA_MONITOR_LAST_DAY"

To check for I/O spikes based on hourly data:


```"code-sql"
select
    trunc(measure_time, 'HH') as interval_hour,
    sum( nproc() * 30 * hdd_read_user_avg)/1024 as total_GB_READ,
    avg( hdd_read_user_avg ) as MB_s_READ,
    sum( nproc() * 30 * hdd_write_user_avg )/1024 as total_GB_WRITTEN,
    avg( hdd_write_user_avg ) as MB_S_WRITE,

    sum( nproc() * 30 * hdd_read_pddsrv_avg)/1024 as total_GB_READ_PDD,
    avg( hdd_read_pddsrv_avg ) as MB_s_READ_PDD,
    sum( nproc() * 30 * hdd_write_pddsrv_avg )/1024 as total_GB_WRITTEN_PDD,
    avg( hdd_write_pddsrv_avg ) as MB_S_WRITE_PDD

from "$EXA_MONITOR_LAST_DAY"
group by 1
order by 1
;
```
## Step 2

### Query concurrency

Getting a nice overview per hour for

* number of statements and avg runtime (aka exa_sql_hourly)
* average number of concurrent statements (aka exa_usage_hourly)
* how many concurrent statements need to read from disk
* percentage of queries with HDD_READ
* average (MB/sec/node) and total (GB/cluster) HDD_READ caused by SQL


```"code-sql"
with k1 as (
    -- preselected statements. Add type filter (COMMAND_NAME) or user filter (sessions/auditing) when required
	select session_id, stmt_id, start_time, stop_time, hdd_read, temp_db_ram_peak, seconds_between(stop_time, start_time) as stmt_duration
	from exa_sql_last_day
)


, k3 as (
    -- Splitting duration-based data into plus/minus events
	select
		session_id, stmt_id, stmt_duration,
		start_time as interval_start, +1 as stmt_delta,
		HDD_READ, case when HDD_READ>0 then +1 else 0 end as HDD_DELTA
		, temp_db_ram_peak
	from k1
UNION ALL
	select
		session_id, stmt_id, stmt_duration,
		stop_time, -1 as stmt_delta,
		HDD_READ, case when HDD_READ>0 then -1 else 0 end as HDD_DELTA
		, temp_db_ram_peak
	from k1
)


, k4 as (
    -- reconnect events into intervals with running totals
	select
		interval_start,
		stmt_delta, stmt_duration,
		sum(stmt_delta) over(order by interval_start) as concurrent_statements,
		sum(hdd_delta) over(order by interval_start) as concurrent_reads,
		sum(hdd_delta*hdd_read) over(order by interval_start) as concurrent_ratio,		
		lead(interval_start) over(order by interval_start) as interval_end
		, sum(temp_db_ram_peak * stmt_delta) over( order by interval_start ) as TEMP_RAM_USAGE
	from k3
)

, k5 as (
    -- prepare for grouping and add RAM-sorted timeline for percent-based RAM estimation
	select
		interval_start,
		trunc(interval_start, 'HH') as interval_hour,
		stmt_delta, stmt_duration,
		seconds_between(interval_end, interval_start) as interval_length,		
		concurrent_statements,
		concurrent_reads,
		concurrent_ratio
		, TEMP_RAM_USAGE
       , sum(local.interval_length) over(partition by local.interval_hour order by TEMP_RAM_USAGE desc NULLS LAST) as time_progression
       , sum(local.interval_length) over(partition by local.interval_hour) as total_time
	from k4
)

select
	-- interval start
	interval_hour,

	-- percentage of time actually spent calculating -- should match with EXA_USAGE_HOURLY
	cast( 100 * sum(case when concurrent_statements > 0 then interval_length end) / greatest(3600,sum(interval_length)) as decimal(6,2) ) as pct_busy,

	-- number of statements started in interval -- should match EXA_SQL_HOURLY
	sum(case when stmt_delta > 0 then 1 end) as statement_count, 

	-- average duration of statements started in interval -- should match EXA_SQL_HOURLY
	cast(avg(case when stmt_delta>0 then stmt_duration end) as decimal(8,3)) as duration_avg,

	-- average (time-weighted) number of concurrent_statements -- should match EXA_USAGE_HOURLY
	cast(sum(concurrent_statements*interval_length)/sum(case when concurrent_statements>0 then interval_length end) as decimal(6,2)) as concurrency_avg, 

	-- new: average number of concurrent statements READING FROM DISK
	cast(sum(concurrent_reads*interval_length)/sum(case when concurrent_statements>0 then interval_length end) as decimal(6,2)) as READERS_AVG, 

	-- new: average (time-weighted) percentage of statements reading from disk
	cast( 100 * sum(interval_length * concurrent_reads / nullifzero(concurrent_statements))/sum(case when concurrent_statements>0 then interval_length end) as decimal(6,2)) as PCT_READERS, 

	-- new: parallelity factor (query_hours per hour) -- equals CONCURRENCY_AVG when BUSY==100
	cast(sum(concurrent_statements*interval_length)/greatest(3600,sum(interval_length)) as decimal(6,2)) as time_compression, 

	-- average HDD_READ per node WHEN BUSY -- indicates HDD throughput under concurrency
	cast(sum(concurrent_ratio*interval_length)/sum(case when concurrent_ratio>0 then interval_length end) as decimal(6,2)) as MB_sec_busy, 

	-- average HDD_READ per node for total hour --  matches EXA_MONITOR_HOURLY.HDD_READ_AVG when ignoring backup, logfiles, etc
	cast(sum(concurrent_ratio*interval_length)/3600 as decimal(6,2)) as MB_sec_interval, 

	-- total HDD_READ caused by SQL, about 10-20% overestimated compared to EXA_MONITOR_HOURLY
	cast(sum( nproc()  * concurrent_ratio * interval_length )/1024 as decimal(10,2)) as GB_read_interval 
	
	-- maximum TEMP_DB_RAM_USAGE peak. SHOULD fit into RAM to avoid swapping
	, cast( max(TEMP_RAM_USAGE) as decimal(9) ) as TEMP_DB_RAM_PEAK
	-- bad average over different-sized intervals ... no relevance
	, cast( avg(TEMP_RAM_USAGE) as decimal(9) ) as TEMP_DB_RAM_AVG
	-- weighted average considering interval sizes ... better
	, cast( sum(TEMP_RAM_USAGE*interval_length)/sum(interval_length) as decimal(9) ) as TEMP_DB_RAM_AVG2
	-- time-based percentile: more than this is used for TEMP in 20% of the time only
	, avg( case when ( total_time * 0.2 ) between time_progression - interval_length and time_progression then TEMP_RAM_USAGE end ) as TEMP_DB_RAM_20
	               
from k5
group by 1
order by 1
;
```
## Additional References

<https://www.exasol.com/support/browse/EXASOL-1598>

<https://www.exasol.com/support/browse/EXASOL-2373>

<https://docs.exasol.com/sql_references/metadata/statistical_system_table.htm?Highlight=concurrency>

