# Statistics export for support 
## Problem

The scripts attached to this issue can be used to gather and export database usage statistics for databases in versions 6.x and 7.x.

## Solution

## Scripts

For Database versions `up to 7.0` we provide scripts on GitHub for three different purposes:

* [3rdLevelStats_leq_DBv70_Indices.sql](https://raw.githubusercontent.com/exasol/exa-toolbox/master/utilities/3rdLevelStats_leq_DBv70_Indices.sql): statistics on indices and database objects
* [3rdLevelStats_leq_DBv70_LastDay.sql](https://raw.githubusercontent.com/exasol/exa-toolbox/master/utilities/3rdLevelStats_leq_DBv70_LastDay.sql): statistics of the last day
* [3rdLevelStats_leq_DBv70_Hourly.sql](https://raw.githubusercontent.com/exasol/exa-toolbox/master/utilities/3rdLevelStats_leq_DBv70_Hourly.sql): hourly statistics for the last x days (x is a script parameter)

For Database versions `starting from 7.1` all statements are combined into one file:

* [3rdLevelStatistics_geq_DBv71.sql](https://raw.githubusercontent.com/exasol/exa-toolbox/master/utilities/3rdLevelStatistics_geq_DBv71.sql)

## Number of Days Parameter

The scripts *3rdLevelStats_leq_DBv70_Hourly.sql* and *3rdLevelStatistics_geq_DBv71.sql* contain a parameter which defines the number of days in the past to export statistics for. When executing the scripts via the command line or the GUI, the user will be prompted to enter this parameter.

## Note:

* The size of the generated CSV's vary and could be quite large - make sure that there is enough space on the directory that you are saving them to.
* The "days" parameter is using EXAplus syntax, which may have to be modified for other clients.
* The scripts use EXPORT to LOCAL CSV, which requires clients using the Exasol JDBC driver (ODBC, ADO.NET etc. would not work).

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 