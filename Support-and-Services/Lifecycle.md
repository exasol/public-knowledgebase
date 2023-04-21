
# Exasol Life Cycle Policy
This page summarizes End-of-Life (EOL) information for the Exasol database, as well as supported platforms and platform versions for drivers and clients.

## Exasol Releases
You can find the latest database release and drivers here: https://downloads.exasol.com

Each release (minor or major) is fully supported for at least two years. This time is extended until two later versions (minor or major) are released.
A release includes all components listed in the below download links.

|  Release | Release Date  | End of Life   |  Remarks  | 
|---|---|---|---|
|  Exasol 6.2 |  2019-07-24 |  2021-12-31 |  out of support since 2021-12-31 |
|  Exasol 7.0 |  2020-09-11 |  2023-06-30 |  extended to 2023-06-30|
|  Exasol 7.1 |  2021-08-03 |  2024-06-30 |  extended to 2024-06-30 |

## Client Platform Support

This section explains which platforms and platform versions are supported for the following clients:

   * ODBC, JDBC, ADO.NET drivers
   * Exaplus SQL client (command line interface)
   * SDK (native C++ call level interface)

### Backward and Forward Compatibility

We strongly recommend you to always using the latest driver version, regardless of the database version. For example we recommend using the 7.1 drivers even if you have the 7.0 Exasol database installed.

The drivers (ODBC, JDBC, ADO.NET) listed on our downloads page are fully backward compatible, i.e. a driver with a specific version is compatible with all database versions with the same or earlier versions. There might be exceptions in rare cases to the backwards compatibility where some old platforms might not be supported by the newest driver anymore. In this case the last supported driver version is mentioned in the remarks column. You can also use an older driver version to connect to a newer database version, however, some of the features may require a minimum driver version and might thus not be available with the old driver.

Due to the backwards compatibility we only release driver updates for the latest released version (major or minor).
The end of Exasol Support for a particular platform is usually bound at least to their individual full/mainstream support end.

|Operating System|	Clients Version|	End of Support by Exasol|	Remarks|
|---|---|---|---|
|**Linux**	|
|CentOS 8 Stream|7.1| tbd| |
|Centos 8|	7.1|	2022-03 or later |incl. RHEL 8|
|Centos 7|	6.2|	2020-12	|incl. RHEL 7|
|CentOS 6|	6.1|	2017-06	|incl. RHEL 6|
|Debian 10|	7.1|	~2022|	|
|Debian 8|	6.2|	2020-06||	
|SLES 15|	7.1|	2022-03 or later||	
|SLES 12|	7.1|	2022-03 or later||	
|SLES 11|	6.2|	2019-03||	
|openSUSE Leap 15.2|	7.1|	2022-01	||
|Ubuntu 20.04 LTS| 7.1|2024-03 or later||
|Ubuntu 18.04 LTS|	7.1|	2022-03 or later||
|**Mac**|	
|OS X 12 (12.0.1)| tbd||
|OS X 11 (11.6.1)| tbd||
|OS X 10.15|	7.1|	tbd|	SDK not supported|
|**BSD**|	
|FreeBSD 12.2|	7.1|	2022-03 or later||
|FreeBSD 11.4|	7.1|	2021-09	||
|**Windows**|	
|Server 2019|	7.1|	2022-03 or later||
|Server 2016|	7.1|	2022-03 or later||	
|Server 2012 R2|	7.1	2022-03 or later||	
|Server 2008 R2|	6.2	2018-12-31||	
|Windows 11|	7.1|	tbd||	
|Windows 10|	7.1|	tbd||	
|Windows 7 SP1|	6.2|	2020-01-14||	

## ADO.NET driver support for Visual Studio, SQL Server and .NET versions.
|Product	|End of Exasol Support|	Supported .NET Framework versions|	Remarks|
|---|---|---|---|
|Visual Studio 2019|	2022-03 or later|	3.5 - 4.8|	supported since 6.2.6 and 7.0.0|
|Visual Studio 2017 Version 15.9|	2022-03 or later|	3.5 – 4.7.1||	
|Visual Studio 2015 Update 3|	2021-10-31|	2.0 – 4.6.2||	
|Visual Studio 2013 Update 5|	2020-12-31|	2.0 – 4.5.2||	

|Java Version|	End of Exasol Support|	Remarks|
|---|---|---|
|SQL Server 2019|	2022-03 or later|	supported since 6.2.6 and 7.0.0|
|SQL Server 2017|	2022-03 or later|	|
|SQL Server 2016 Service Pack 2|	2022-03 or later|	
|SQL Server 2014 Service Pack 3|	2020-07-31|	

## JDBC Version (& Java Version)
Earlier versions than 6.2.3 supported JDBC 3.0. Since 6.2.3 we support JDBC 4.1.

|Java Version|	End of Exasol Support|	Remarks|
|---|---|---|
|Java SE 13|	tbd	||	
|Java SE 11|	tbd	||
|Java SE 9|	2022-03-31|	|
|Java SE 8|	2022-03-31|	|
|Java SE 7|	2021-07-31|	last supported in 7.0.11|

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 