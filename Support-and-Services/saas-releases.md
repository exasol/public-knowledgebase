# SaaS Release Notes

This page contains the release notes for [Exasol SaaS](https://cloud.exasol.com).

For further information please also visit related pages for Exasol SaaS:
* [SaaS Documentation](https://docs.exasol.com/saas)
* [Status Page (status.exasol.com)](https://status.exasol.com)

## June 14
UI and Platform Update
* Improved dialogs for communication of credit status to free trial users.
* Added the ability to apply for a free trial extension through the UI.
* Fix for problems with the cluster auto stop feature.
* Fixes for internal solution management issues.
* Disabled the ability to edit entries in the network security list in the UI and Rest API.  Users are now required to remove existing entries and create new ones rather than modifying existing entries.
* Prevent users from accidentally disabling browser cookies essential to the UI.


## June 07
Platform Update
* Hotfix for internal platform problems.
* Use Exasol DB version 8.18.1 for new database deployments.  See the release notes here:  https://docs.exasol.com/db/latest/release_notes/8.18.1.htm


## May 30
UI and Platform Update
* Use Exasol DB version 8.17.0 for new database deployments.  See the release notes here:  https://docs.exasol.com/db/latest/release_notes/8.17.0.htm
* Include user interface for uploading custom files to a deployment (available for Trial and Enterprise users only).
* Use Google Recaptcha on account signup.
* Improved response time for UI and database/cluster browsing rest API operations.
* Removed Rest API compatibility with legacy Okta account IDs which were replaced in December 2022 but supported until now for compatibility.  The account ID you use in the Rest API should now begin 'org' and is obtainable in the SaaS UI.  Using an Okta ID in the rest API will now result in a 401 error for some endpoints.
* Fixed a bug where attempting to change the size of a deployment which is running could sometimes result in the deployment being stopped after the resize completes.


## May 17
Platform Update
* Add the new 'bfssaas' bucketfs bucket to all existing and new deployments in Trial or with Enterprise subscriptions.
* Add the capability to upload custom UDF files to a a deployment's bfssaas bucket via the SaaS rest API.
* Further improved the SaaS API response times for a faster UI and rest API.
* Minor bugfixes and improvements.


## April 18
UI and Platform Update
* Improvements to reliability of database and cluster management operations.
* Use a new bugfix release of Exasol DB 8.9.0 for new deployments.
* Existing 8.9.0 deployments will be updated on a schedule.
* Added graphical visualisation of query results to SQL worksheets.
* Improved the SaaS API response times for a faster UI and rest API.
* Eliminated the problem where the SaaS rest API occasionally returns an error and requires a retry.
* Minor bugfixes and improvements.


## March 17
UI Update to v1.224.0
* Improve service usage card for pre-purchase customers.
* Hide additional data for timestamp data types in SQL worksheets .


## March 01
Platform Update
* Use Exasol DB 8.9.0 for new database deployments.  See the release notes here:  https://docs.exasol.com/db/latest/release_notes/8.9.0.htm
* General improvements of the reliability of database and cluster management operations.
* Fix for problems experienced when XS deployments are put under heavy load.
* Fixed an issue where some XS deployments failed to start due to AWS instance launch problems.
* Minor bugfixes and improvements.


## March 01
UI Update to v1.222.2
* Improved error handling and reporting in the UI.
* SQL Worksheet, schema browser and query result grid improvements.
* update cookies in privacy policy page.
* Improve PAT creation dialog.


## February 01
UI Update to v1.212.0
* Database driver update.
* Add re-invite button to user invitation list.
* Terms of service update to V21.
* Improvements for user/invitation list and name changes.
* UI loading time improvements.
* Tabs show button style tabs correctly.


## January 22
Platform Update
* Platform security improvements.
* Minor bugfixes and improvements.


## January 10
UI Update
* Improvements to new user signup.
* Improvements to e-mail validation.


## December 21
UI Update
* Bug fixes for user invitation behaviour.


## December 10
Platform Update
* Switched the authentication provider to Auth0 instead of Okta.  Account migration instructions have been sent by email.
* New Account IDs have been issued for use in the rest API and can be obtained via the SaaS UI.

## November 08
Platform Update
* Fixed an issue where creating a database is sometimes stuck in the state "Creating" forever.

Database Update
* We released Exasol 8.6.0 for SaaS. Please refer to the [8.6.0 release notes](https://docs.exasol.com/db/8.x/release_notes/8.6.0.htm) for a list of changes.
* Note: At this time the new database version is only effective for new databases. Please contact support for updating existing databases.


## October 13
Platform Update
* Fixed an issue where sometimes starting all clusters results in error state
* General improvements of the reliability of database and cluster management operations


## August 29
Platform Update
* Fixed an issue where VPC peering could not be enabled due to a wrong internal IP range. VPC peering is a feature of the enterprise edition which can be enabled on request.


## August 16
Platform Update
* Fixed an issue where the REST API GET cluster operation sometimes returns the state from a different worker cluster of the same database.
* Fixed an issue where after the update of a customer database, new worker clusters will still be created with the previous database version.
* Fixed an issue where some customer could not signup because of wrong email validation


## August 9
UI Update
* Fixed an issue in Worksheets, where sometimes the cursor position was wrong.
* Added an improvement to offer a getting starting video as part of the initial onboarding. The video can be watched while waiting for the creation of the first database.

Platform Update
* Internal improvements to our monitoring, for improved reliability


## July 19th
UI Update
* Worksheet now remembers if the schema browser was collapsed by the user or not.
* Improved error message for sign in case of a planned platform maintenance, including a link to our status page.
* Fixed a bug in Worksheets where deleting the whole content of a worksheet was sometimes reverted by the system
* Fixed a bug in Worksheets where sometimes changes were not saved when navigating away from the worksheet short after making the change.


## July 12th
Platform Update
* Fixed several issues where in special cases a cluster could get into the "Error" state.
* Fixed an issue where a user invited to a stopped database will wrongly see the "Creating" state, although the database is actually stopped.
* Fixed an issue where the REST API cluster status could sometimes return "Running" state too early, although the database is not completely ready to be used. This was also inconsistent with the databases state.

UI Update
* We introduced a new preview feature "schema browser for Worksheets". You can now browse your database schemas, tables and other metadata using the schema browser, available in the left side bar on the worksheet page. Following objects are supported:
  - Schemas, separated by user schemas, system schemas and virtual schemas
  - Tables, Views, and columns with type information
  - Users and roles
  - UDFs
  - Virtual Schema Adapters
  - Lua Scripts
  - Functions
* Fixed an issue in Worksheets where sometimes the wrong font type was used when the desired font was not available on the system.
* Fix an issue in Worksheets it could happen that a wrong cluster state was shown.
* New JDBC driver 7.1.11

## July 5th
UI Update
* We added pay-as-you-go support for following countries: Australia, Brazil, Canada, New Zealand, Singapore. Previously, organizations from these countries could already participate in the free trial, but could only choose the pre-purchase payment model afterwards.


## June 21st
Platform Update
* The speed of database creation was improved, so in most cases it is expected to take less than 5 minutes.
* Fixed wrong prices shown in the UI when creating a database or cluster, where some prices were not consistent with the prices shown on https://www.exasol.com/exasol-saas/.

Database Update
* Fix IMPORT FROM JDBC, which is currently failing in some cases. (Sometimes restarting the database fixes the problem)
* Note: The new version is only effective for new databases. Please contact support for updating existing databases.


## June 8th
UI Update
* Improved SQL worksheets to keep the focus in the SQL editor after running a statement, to enable running interactive SQL statements with keyboard only. Before the keyboard focus changed to the result set.
* Minor improvement to names of Personal Access Tokens which are autogenerated in the "Connect via tool" wizard. So far the PAT name included the cluster name, wrongly indicating that the PAT is bound to a cluster.


## June 3rd
Database update
* Fixed a bug where UDFs and Virtual Schemas were not working and returned the following error: 22061: Cannot access bucket 'slc' in bucketfs '__builtin__'
* Note: New version is only effective for new databases. Please contact support for updating existing databases.


## May 19
Platform Update
* The speed of database creation was improved, so in most cases it is expected to take less than 5 minutes.
* Stability improvements to fix a problem where cluster management functionality could stop working. This fixes the underlying problem which caused the incident on May 18, which is documented on https://status.exasol.com/.


## May 16
UI Update
* Fixed a bug where Worksheets was not able to connect to a database in rare circumstances.
* Fixed a bug in Worksheets where scrolling with the mouse did sometimes not show the last row.

## May 9
UI Update
* Fixed a bug in Worksheets where after an error sometimes a statement remained highlighted as error although it was successfully executed afterwards

## May 4
UI Update
* The enterprise hotlines are now shown in the support dialog, for all users of an organization with enterprise edition.
* The navigation bar is now collapsable and expandable. Initially the menu is expanded on large screens, which improves usability.
* Fixed a display bug in worksheets, where worksheets was no longer usable after navigating back and forth in browser history.
* Stopped clusters can now be resized. The resize will be considered next time the user starts the cluster.

Platform Update
* Fixed a bug where granting access to a database (DB1) can lead to ungranting access for another database (DB2). This happened if the inviting person has no access to the other database DB2.

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 