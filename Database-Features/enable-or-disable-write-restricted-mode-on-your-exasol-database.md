# Enable or Disable Write Restricted Mode on your Exasol database 
## Scope

As you may know, the Exasol database is enforced by limits when the License (RAW-based or RAM-based) is exceeded. We can use this enforcement to enable or disable the "Write Restricted Mode" to prevent temporarily data insertion on the database. In this article, we will explain how you can achieve this.

## Diagnosis

Exaoperation logs or EXA_SYSTEM_EVENTS table will tell you whether you have reached the License limits or not. A Warning message will look like this: 


```html
License Warning: Databases raw sizes of 87.0 GiB is close to the license limit of 100.0 GiB (86.5%). 
At 105% databases will no longer permit data insertion.
```
And the Error message as:


```html
License exceeded: Databases raw sizes of 53.0 GiB exceed license limit of 50.0 GiB (106.2%). 
Databases no longer permit data insertion.
```
Querying the EXA_SYSTEM_EVENTS table you will see the below messages (within others) when the "Write Restricted Mode" is enabled and when it is disabled:


```sql
CLUSTER_NAME MEASURE_TIME        EVENT_TYPE       DBMS_VERSION NODES DB_RAM_SIZE PARAMETERS
MAIN         2021-07-12 08:30:02 LICENSE_OK       7.0.11       4     600.0
MAIN         2021-07-10 14:02:59 LICENSE_EXCEEDED 7.0.11       4     600.0
```
## Explanation

Exasol provides 2 different licenses: "Raw data License" (default one) and "Database RAM License". For further details follow [this](https://docs.exasol.com/administration/on-premise/licenses.htm "Licenses") link. We have already mentioned that there are certain limitations enforced on the license and a periodic check is done by Exasol on the size of the data. In this article, we will talk only about the case your Exasol License is a "Raw data License".

In this case, when the Raw size of the database exceeds **105%** of the license, the database **won't permit any further data insertion** and therefore a "Write Restricted Mode" is enabled. The statements that are affected in this mode are IMPORT, INSERT, CREATE TABLE AS, MERGE, SELECT INTO.

## Recommendation

There are 2 options to achieve this goal, the first one is to fill up the database until you reach 105% of the license, the second one is to update the license with a smaller one. This is the prefered method and the one we will explain below.

 This "feature" was not designed for making the database "Read-only" and therefore we recommend to test this very carefully on a TEST environment first. 

## "Write Restricted Mode" - License update

This solution will trigger the "Write Restricted Mode" by updating the cluster with a smaller license. Please ensure the temporarily license Raw data value is at least 105% of the current raw size of the database. 

In order to update the license, you can follow the instructions on this [link](https://docs.exasol.com/administration/on-premise/manage_software/activate_license.htm "License"). However, you may want to change the new one without disruption or without the need to restart the database. To do so, you just need to skip step -4- from the instructions. The full procedure will look like this:


```html
1) Check "EXA_SYSTEM_EVENTS" or EXAOperation logs for the messages.

2) Upload the "temporary" license with a smaller RAW allowance) into EXAOperation.

3) Connect to the database as SYS or a DBA user and run "FLUSH STATISTICS TASKS;".

4) Wait for 3 to 5 minutes. 
The activation of the new license takes about 3 to 5 minutes, then the "Write Protected Mode" will be activated and all of the commands including INSERT and CREATE AS SELECT will stop working.

5) Check again "EXA_SYSTEM_EVENTS" or EXAOperation logs for the correspondent messages
```
## Revert to "Normal Mode"

To revert back the License, you must follow the same procedure described above with the "real" License instead of the "temporary" on step (2).

## Additional References

Here you link to other sites/information that may be relevant.

<https://docs.exasol.com/planning/licensing.htm>

<https://docs.exasol.com/sql_references/system_tables/statistical/exa_system_events.htm>

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 