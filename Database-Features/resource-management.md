# Resource Management 
## Background

Exasol provides fully automatic resource management, that distributes all available resources among all active queries within the database.   
Within Exasol there are four different resources available and the performance statistics can be found in EXA_STATISTICS.EXA_DBA_PROFILE_LAST_DAY or in EXA_STATISTICS.EXA_MONITOR_LAST_DAY:

1. CPU
2. RAM
3. Network
4. Disks

## Explanation

## Details

Exasol attempts to use as many resources as possible by internal parallelization (multi-threading). If there is more than one active query the resource management distributes the available resources among those. By default, all queries are treated equally. By using consumer groups (see <https://docs.exasol.com/db/latest/database_concepts/resource_manager.htm>) the resource distribution can be influenced.  
The resource management distinguishes between "short" and "long" queries:

* Short: queries running less than 5 seconds
* Long: queries running more than 5 seconds

If the number of long queries exceeds the number of (logical) cores per server times 1.5 (e.g. 36 if the servers have 24 logical cores), the resource management pauses and restarts those queries automatically. In this case, time slices of 20 seconds are provided for the long queries that are not being paused. Short queries are not affected by this.  
This concept is designed to provide an optimal throughput for mixed workloads (Short and long queries).

Time slice allocation, especially entering PAUSED mode requires pre-emptive action by the affected process. Therefore the 20 seconds are not always an exact measure, but require query execution to reach certain checkpoints. Those checkpoints are very frequent for regular execution, but recently it was detected that for example, an 'active' prepared statement that is actually waiting for more client data does**not**enter such a checkpoint until a data packet arrives. Until this is improved on the database side, we recommend closing prepared statements whenever the application realizes it will have to wait for more data.

