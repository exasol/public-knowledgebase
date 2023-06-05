 # V8 FAQ
 ## General Information
 
 ### Exasol version 8 is build on a different architecture but fully supporting upgrades from older versions.
The major difference to 7.x is that with v8, Exasol is decoupling the OS and database layer, not shipping anymore the underlying OS CentOS-7.

### Documentation
Documentation about v8 can be found on Exasol documentation page available at https://docs.exasol.com/home.htm - select Version 8 (latest) from the drop-down then navigate to the EXASOL DATABASE part.

In general the upgrade procedure is done like shown below:
- backup the 7.1 database to an external location
- install new v8 database - get it from https://downloads.exasol.com/exasol-8 
- restore backup 7.1 into the new 8.x database
- upload your updated v8 license

### Licensing
Exasol v8 has a different licensing model as such the v7.x licenses cannot be used on v8 systems. Please get in touch with Exasol Support to retrieve a new v8 license.

### New v8 installations
Installation instructions can be found on the Exasol documentation page, for customer who booked "Cluster Administration Service" or "Platinum Support Level" - the Exasol Support will take care about the installation. For all others please get in touch with your Account Manager in order to get a quote.

### Migration Service
Exasol will help all customers to have a smooth transition to v8. Customer who booked "Platinum Support Level" and "Cluster Administration Service" will get this service complimentary and free or charge. For all others Exasol is offering a "v8 Migration Service", for details either get in touch with Support or with your Account Manager.

The “v8 Migration Service” comprises supporting tasks for the upgrade and migration from a supported Exasol version to the latest v8 and includes the following services during the project phase:
* Project Management throughout the whole migration
* Cluster Administration Service
* Cluster Installation Service
* V8 EXAcademy Upgrade Course
* V8 Release Note mentioning supported OS (RedHat Enterprise Linux, and Ubuntu 22.04.2 LTS)

Cooperation and Customer Responsibility:
* provide as needed additional resources (e.g., external Backup space, additional clusters)
* Commit to the commonly agreed project plan|

### How long can I use version 7.0 oder 7.1 before I have to upgrade to V8.0

You can find the EOL dates for release here: https://exasol.my.site.com/s/article/Exasol-Life-Cycle-Policy?language=en_US

### I am using V7.x. How can I upgrade?
 
 Due to the to the new architecture in V8 including the separation of the database software from the operating system (Exasol will not deliver CentOS anymore), upgrading a v7.1 cluster to V8 using an update installation package is not feasible. 
 Instead, a reinstallation is required. 
 For details please refer to the documentation: https://docs.exasol.com/db/8.x/administration/aws/upgrade/migrate_71_v8.htm 
 
 Our Support team is available to assist you throughout the entire process. 
 You have the choice to perform the upgrade procedure on your own or reach out to our support team for guidance. 
 To simplify the migration process, you can take advantage of our "V8 Migration Service." 
 This service is designed to facilitate a smooth and hassle-free transition to V8.  

## OS Support

### I am an ExaCloud customer. What does the separation of database software and operating system in v8 mean for me?

You don't need to worry about making any changes yourself. We will take care of planning and executing the upgrade for you. Our team will contact you to coordinate the necessary downtime for the upgrade process.

### I use an Exasol Appliance. What does the separation of database software and operating system in v8 mean for me?

We will handle the management of the operating system for the entire duration of your existing contract. If you require more information about potential changes that may occur when extending your contract, please contact your account manager.

To discuss the planning of the upgrade to V8 and our dedicated service offerings, please reach out to our customer service team via service@exasol.com  They will assist you with the necessary steps, provide further guidance and service offerings.

### I have booked the platinum service, the cluster administration and/or cluster installation service. What does the separation of database software and operating system for me?

Due to the separation of the operating system and database software, the V8 services do not cover the management of the operating system anymore.
Please get in touch with your account manager or our customer support via service@exasol.com for more details.

### Which operating system shall I use

We recommend Ubuntu 22.04 LTS and Redhat Enterprise Linux RHEL 9.x

## V8 Fundamentals

### Where will version 8 be available?

V8 is already used in SaaS.
Now V8 is available for AWS and on-premises.
The on-premise version is also referred to as "as-Application" version as it cannot only be installed on bare metal hardware but also on top of any VM running a x86 Linux operating system.

### What are the functional differences between the Cloud-versions and the on-premise ("as application") version

#### V8 Cloud
* Includes Storage/Compute decoupling based on cloud-provider based native object stores (AWS S3).
* Supports multi-cluster configurations (based on your license)

#### V8 on-premises
* Leverages block storage (like 7.x) and therefore does not support object-store based storage-compute decoupling
* Single cluster only (multi-cluster architecture not supported)

### Does V8 come with an administration application like ExaOperation

As more and more customers automate installation and configuration, V8 does not come with an administration UI.
V8 comes with powerful APIs and configuration/installation tools. Please have look at the V8 documentation (https://docs.exasol.com/db/latest/home.htm).

### How can I familiarize myself with version 8 before updating my databases? 

SaaS already runs a version 8. SaaS also offers a free trial and there offers the most convenient way to test v8.

Alternatively, you can could launch a new cluster on AWS using V8 or a single cluster based on the v8 Docker image.

Please first update test or staging environment as usual.

Feel free to reach out to your account manager, and our team of capable solutions engineers will be glad to provide assistance and support upon contact.

## Deployment specific questions

### Does Exasol V8 will become available in the Cloud marketplaces

Yes, we will publish v8 in the cloud marketplaces at a later point in time. Our primary goal is to launch V8 first on all platforms.

## Contact Support
Exasol Support can be contacted as described on this page https://exasol.my.site.com/s/?language=en_US 

