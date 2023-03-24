# EXAoperation how-to activate a new license 
## Background

This article explains how to activate a new license.

Scenario: License Upgrade with DB RAM expansion

## Prerequisites:

* The valid license file (XML)
* Short Downtime to stop and start the database
* EXAoperation User with privilege Level "Master"

## Explanation

#### Step 1: Upload License file to EXAoperation

* In EXAoperation, navigate to "Software"
* On the software page, click on the "License" Tab
* Click on the "Browse" button to open a file upload dialog. Select the new license file and confirm by clicking the "Upload" button
* Refresh the "License" page and review new license information

#### Step 2: Stop all databases

* Click on left navigation pane "EXASolution"
* Select all checkboxes of the listed database instances
* Click on the "Shutdown" button and wait for all database instances to shut down (Monitoring->Logservice)

#### Step 3: Adjust DB RAM (optional)

* Click on the DB name
* Click on "Edit"
* Adjust "DB RAM (GiB)" according to your license and click "Apply"

#### Step 4: Start all databases

* Click on left navigation pane "EXASolution"
* Select all checkboxes of the listed database instances
* Start all databases and wait for all instances to be up and running (Monitoring->Logservice)

## Additional References

<https://docs.exasol.com/administration/on-premise/manage_software/activate_license.htm>

