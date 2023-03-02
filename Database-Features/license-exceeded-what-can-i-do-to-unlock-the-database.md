# License Exceeded. What can I do to unlock the database? 
## Scope

The Exasol database is enforced by limits when the License (RAW-based or RAM-based) is exceeded. If this is your case, you will get an error message. We will explain what you can do in order to unlock the standard operation of the database.

## Diagnosis

When the limits are reached, you will see the following in the Exaoperation logs or by checking the EXA_SYSTEM_EVENTS table:

Warning Message:


```html
License Warning: Databases raw sizes of 87.0 GiB is close to the license limit of 100.0 GiB (86.5%). 
At 105% databases will no longer permit data insertion.
```
Error Message:


```html
License exceeded: Databases raw sizes of 53.0 GiB exceed license limit of 50.0 GiB (106.2%). 
Databases no longer permit data insertion.
```
EXA_SYSTEM_EVENTS Messages:


```sql
CLUSTER_NAME MEASURE_TIME        EVENT_TYPE       DBMS_VERSION NODES DB_RAM_SIZE PARAMETERS
MAIN         2021-05-18 14:02:59 LICENSE_OK       7.0.9        3     100.0       -forceProtocolEncryption=1
MAIN         2021-05-17 13:34:02 LICENSE_EXCEEDED 7.0.9        3     100.0       -forceProtocolEncryption=1
```
## Explanation

Depending on your contract with Exasol and your business requirements, Exasol provides 2 different licenses: "Raw data License" (default one) and "Database RAM License". For further details follow [this](https://docs.exasol.com/administration/on-premise/licenses.htm "Licenses") link.

There are certain limitations enforced on the license and a periodic check is done by Exasol on the size of the data. 

If you have a "Database RAM License", you won't be able to allocate more RAM at the time you start the database. On the other hand, if you have a "Raw data License" and the size limit exceeds **105%**, the database **won't permit any further data insertion** (statements affected: IMPORT, INSERT, CREATE TABLE AS, MERGE, SELECT INTO) until the usage drops below the specified value or the license is changed.

## Recommendation

To resolve the limit exceeded on your license, you have 2 options:

## 1. Delete data

The first solution is to clear some large data (DROP or DELETE database tables). When this is done, connect as SYS (or DBA) and perform "FLUSH STATISTICS TASKS;" on the database to trigger the check; the (de)activation of the "Restricted Mode" takes about 3 to 5 minutes.

Please note, it is important to clear sufficient data so we are back below 100% of the license. Additionally, you can check the[ EXA_DB_SIZE_LAST_DAY](https://docs.exasol.com/sql_references/system_tables/statistical/exa_db_size_last_day.htm)table to view information on database sizes.

## 2. License update

A second solution might be to update the License. This can take some time, therefore if you are already in negotiations with Exasol, please tell Exasol Support (see some details [here](https://www.exasol.com/product-overview/customer-support/ "Exasol")).

If you are holding a Raw data license, you may want to change the new one without disruption. To do so, please follow the steps below:


```html
1) Check "EXA_SYSTEM_EVENTS" or EXAOperation logs for the messages  
2) Upload the "new" license (with a bigger RAW allowance), into EXAOperation following the below link (Note: Skip step #4 to not perform the restart): https://docs.exasol.com/administration/on-premise/manage_software/activate_license.htm  
3) Connect to the database as SYS or a DBA user and run "FLUSH STATISTICS TASKS;".  
4) After some time (the (de)activation of the new license takes some time (about 3 to 5 minutes)), the Normal operational mode will be restored and all of the commands including INSERT and CREATE AS SELECT will start working again.  
5) Check again "EXA_SYSTEM_EVENTS" or EXAOperation logs for the correspondent messages
```
## Additional References

Here you link to other sites/information that may be relevant.

<https://docs.exasol.com/planning/licensing.htm>

<https://docs.exasol.com/sql_references/system_tables/statistical/exa_system_events.htm>

