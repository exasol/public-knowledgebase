 # V8 FAQ
## Exasol 8 Fundamentals

### Where will Exasol 8 be available?

Exasol 8 is already used in SaaS.
Now Exasol 8 is available for AWS and on-premises.
The on-premise version is also referred to as "as-Application" version as it can be installed on bare metal hardware as well as on top of a VM running a x86 Linux operating system.

### What are the functional differences between the Cloud-versions and the on-premise ("as application") version?

#### Exasol 8 Cloud
* Includes Storage/Compute decoupling based on cloud-provider based native object stores (AWS S3).
* Supports multi-cluster configurations (based on your license)

#### Exasol 8 on-premises
* Leverages block storage (like 7.x) and therefore does not support object-store based storage-compute decoupling
* Single cluster only (multi-cluster architecture not supported)

### Does Exasol 8 come with an administration application like ExaOperation?

As more and more customers automate installation and configuration, Exasol 8 does not come with an administration UI.
Exasol 8 comes with powerful APIs and configuration/installation tools. Please have look at the Exasol 8 documentation (https://docs.exasol.com/db/latest/home.htm).

### How can I familiarize myself with version Exasol 8 before updating my databases? 

SaaS already runs a version Exasol 8. SaaS also offers a free trial and there offers the most convenient way to test Exasol 8.

Alternatively, you can could launch a new cluster on AWS using Exasol 8 or a single node based on the Exasol 8 Docker image.

Please first update test or staging environment, as usual.

Feel free to reach out to your account manager, and our team of capable solutions engineers will be glad to provide assistance and support upon contact.

### Where can I learn more about Exasol 8?
Our [documentation](https://docs.exasol.com/db/latest/home.htm) is the best place to start on learning more about Exasol 8, especially [What's New in Exasol 8](https://docs.exasol.com/db/latest/get_started/whats-new-in-v8.htm). Our free Exacademy course [Exasol 8 for Early Adopters](https://exacademy.exasol.com/courses/course-v1:Exasol+8NEW+X/about) goes through all of the new features and changes that you need to know when migrating to version Exasol 8.

## Migrations
### How do I migrate from Exasol 7 to Exasol 8?

Due to the to the new architecture in Exasol 8, including the separation of the database software from the operating system, upgrading a version 7.1 cluster to Exasol 8 using an update installation package is not feasible. Instead, a new installation and migration is required.

In general, the migration procedure involves taking a backup of an existing database on version 7.1 and restoring this into a new installation running Exasol 8. The downtime required for the update depends on several factors, such as the amount of data and nodes you have, network speed, and more. More information can be found in our [documentation](https://docs.exasol.com/db/latest/administration/aws/upgrade/migrate_71_v8.htm)

### Can I use my existing license for Exasol 8?
Version 7.x licenses are not compatible with Exasol 8. Please contact us to obtain a new license file specifically for Version 8.

### Will Exasol help us migrate to Exasol 8?
Exasol will help all customers have a smooth transition to Exasol 8. Customers who have booked "Platinum Support Level" or "Cluster Administration Service" will get this service complimentary and free of charge. For all others, Exasol is offering an "Exasol 8 Migration Service".

The “Exasol 8 Migration Service” comprises supporting tasks for the upgrade and migration from a supported Exasol version to the latest v8 and includes the following services during the project phase:
* Project Management throughout the whole migration
* Cluster Administration Service
* Cluster Installation Service
* Exasol 8 EXAcademy Upgrade Course
* Exasol 8 Release Note mentioning supported OS (RedHat Enterprise Linux, and Ubuntu 22.04.2 LTS)

Cooperation and Customer Responsibility:
* Provide as needed additional resources (e.g., external Backup space, additional clusters)
* Commit to the mutually agreed project plan

For information about the Migration Service, contact your account manager.


### How do I install Exasol 8 on my own?
Installation instructions can be found on the [Exasol documentation page](https://docs.exasol.com/db/latest/home.htm). For customers who booked "Cluster Administration Service" or "Platinum Support Level", Exasol Support will take care about the installation. For all others please get in touch with your account manager in order to get a quote.


### How long can I use version 7.0 or 7.1 before I have to migrate to Exasol 8?

You can find the End-Of-Life dates for our releases here: https://exasol.my.site.com/s/article/Exasol-Life-Cycle-Policy?language=en_US

## OS Support

### I am an ExaCloud customer. What does the separation of database software and operating system in Exasol 8 mean for me?

You don't need to worry about making any changes yourself. We will take care of planning and executing the upgrade for you. Our team will contact you to coordinate the necessary downtime for the upgrade process.

### I use an Exasol Appliance. What does the separation of database software and operating system in Exasol 8 mean for me?

We will handle the management of the operating system for the entire duration of your existing contract. If you require more information about potential changes that may occur when extending your contract, please contact your account manager.

To discuss the planning of the upgrade to Exasol 8 and our dedicated service offerings, please reach out to our customer service team via service@exasol.com  They will assist you with the necessary steps, provide further guidance and service offerings.

### I have booked the platinum service, the cluster administration and/or cluster installation service. What does the separation of database software and operating system mean for me?

Due to the separation of the operating system and database software, the Exasol 8 services do not cover the management of the operating system anymore.
Please get in touch with your account manager or our customer support via service@exasol.com for more details.

### Which operating system shall I use?

We recommend Ubuntu 22.04 LTS and Redhat Enterprise Linux RHEL 9.x


## Deployment-specific questions

### Will Exasol 8 become available in the Cloud marketplaces?

Yes, we will publish Exasol 8 in the cloud marketplaces at a later point in time. Our primary goal is to launch Exasol 8 first on all platforms.

## Contact Support
Exasol Support can be contacted as described on this page https://exasol.my.site.com/s/?language=en_US 

