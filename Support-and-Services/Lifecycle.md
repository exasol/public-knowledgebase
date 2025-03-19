
# Exasol Life Cycle Policy
This page summarizes End-of-Life (EOL) information for the Exasol database, as well as supported platforms and platform versions for drivers and clients.

## Exasol Releases
You can find the latest database release and drivers here: https://downloads.exasol.com

The release policy starting with version 8 can be found here: https://docs.exasol.com/db/latest/planning/life_cycle.htm

|  Release | Release Date  | End of Life   |  Remarks  | 
|---|---|---|---|
|  Exasol 6.2 |  2019-07-24 |  2021-12-31 |  out of support since 2021-12-31 |
|  Exasol 7.0 |  2020-09-11 |  2023-06-30 |  extended to 2023-06-30|
|  Exasol 7.1 (Regular Support) |  2021-08-03 |  2024-06-30 |  extended to 2024-06-30 |
|  Exasol 7.1 (Extended Support) | 2024-07-01 | 2025-06-30* | See below note | 
|  Exasol 8 AWS (RR) | 2023-06-01 | | 
|  Exasol 8 as Application (RR) | 2023-06-01 | | 

\* Reach out to your account executive to discuss next steps.

Extended Support for Exasol 7.1 includes:
* OS patches (via 3rd party provider)
* Major bug fixes
* Security Fixes

## End of Life Versions
Once a version reaches End of Life, there are no more software updates, investigations, or bugfixes for that affected version. Incidents which occur on that version are not guaranteed to be processed or resolved, and no SLAs are applicable to these cases. For this reason, we strongly recommend to run supported versions.


## Client Platform Support

This section explains which platforms and platform versions are supported for the following clients:

   * ODBC, JDBC, ADO.NET drivers
   * Exaplus SQL client (command line interface)
   * SDK (native C++ call level interface)

### Backward and Forward Compatibility

We strongly recommend to always using the latest driver version, regardless of the database version. For example we recommend using the 24.0 drivers even if you have the 7.1 Exasol database installed.

The drivers (ODBC, JDBC, ADO.NET) listed on our downloads page are fully backward compatible, i.e. a driver with a specific version is compatible with all database versions with the same or earlier versions. There might be exceptions in rare cases to the backwards compatibility where some old platforms might not be supported by the newest driver anymore. In this case the last supported driver version is mentioned in the remarks column. You can also use an older driver version to connect to a newer database version, however, some of the features may require a minimum driver version and might thus not be available with the old driver.

Due to the backwards compatibility we only release driver updates for the latest released version (major or minor).
The end of Exasol Support for a particular platform is usually bound at least to their individual full/mainstream support end.
## ODBC Driver
The ODBC (Open Database Connectivity) driver is fully supported until the end of life of the operating system. If there is an explicitly stated end-of-life date for the driver, that takes precedence.

|Operating System|	Exasol Client Version|	End of Support by Exasol|	Remarks|
|---|---|---|---|
|**Linux**	|
|CentOS 8 Stream|24.0|| |
|Centos 7|	24.0|	||
|openSUSE Leap 15.5|	24.0| ||
|Ubuntu 22|	24.0|	|	|
|Ubuntu 20|	24.0|	|  |	
|Debian 10|	24.0|	|  |	
|**Mac**|	
|OS X 14| 24.0||  ARM and Intel Architectures are supported. SDK not supported|
|OS X 13| 24.0||  ARM and Intel Architectures are supported. SDK not supported|
|OS X 12| 24.0||	ARM and Intel Architectures are supported. SDK not supported|
|**BSD**|	
|FreeBSD 14.0|	24.0|	||
|FreeBSD 13.2|	24.0|	||
|**Windows**|	
|Server 2022|	24.0|	||
|Server 2019|	24.0|	||
|Server 2016|	24.0|	||	
|Windows 11|	24.0|	||	
|Windows 10|	24.0|	||	

## ADO.NET driver support for Visual Studio, SQL Server and .NET versions.
ADO.Net is fully supported until the end of life of the Visual Studio version it is associated with. If there is an explicitly stated end-of-life date for ADO.Net within a particular Visual Studio version, that takes precedence over the support provided by Visual Studio.

|Product	| Version | Exasol Client Version | End of Exasol Support|	Remarks|
|---|---|---|---|---|
|Visual Studio 2022| 17.0 | 24.0 | 	|	|
|Visual Studio 2019| 16.0 | 24.0 | 	|	|
|Visual Studio 2017| 15.0 | 24.0 | 	|	|
|Visual Studio 2015| 14.0 | 24.0 | 	|	|



## JDBC Version (& Java Version)

The JDBC (Java Database Connectivity) driver is fully supported until the end of life of the Java version it is compatible with. If an explicit end-of-life date is specified for the driver, it takes precedence.

|Java Version|	Exasol Client Version| End of Exasol Support|	Remarks|
|---|---|---|---|
|Java SE 17|24.0|||
|Java SE 11|24.0|||
|Java SE 8|24.0|||

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 
