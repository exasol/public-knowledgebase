 # V8 FAQ
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

### Where can I learn more about v8?
Our [documentation](https://docs.exasol.com/db/latest/home.htm) is the best place to start on learning more about v8, especially [What's New in v8](https://docs.exasol.com/db/latest/get_started/whats-new-in-v8.htm). Our free Exacademy course [Exasol 8 for Early Adopters](https://exacademy.exasol.com/courses/course-v1:Exasol+8NEW+X/about) goes through all of the new features and changes that you need to know when migrating to version 8.

## Migrations
### How do I migrate from v7 to v8?

Due to the to the new architecture in V8, including the separation of the database software from the operating system, upgrading a v7.1 cluster to V8 using an update installation package is not feasible. Instead, a new installation and migration is required.

In general, the migration procedure involves taking a backup of an existing database on version 7.1 and restoring this into a new installation running version 8. The downtime required for the update depends on several factors, such as the amount of data and nodes you have, network speed, and more. More information can be found in our [documentation](https://docs.exasol.com/db/latest/administration/aws/upgrade/migrate_71_v8.htm)

### Can I use my existing license for v8?
Exasol v8 has a different licensing model, which means that the v7.x licenses cannot be used on v8 systems. Please get in touch with Exasol Support or your account manager to recieve a new v8 license.

### Will Exasol help us migrate to v8?
Exasol will help all customers have a smooth transition to v8. Customers who have booked "Platinum Support Level" and "Cluster Administration Service" will get this service complimentary and free or charge. For all others, Exasol is offering a "v8 Migration Service".

The “v8 Migration Service” comprises supporting tasks for the upgrade and migration from a supported Exasol version to the latest v8 and includes the following services during the project phase:
* Project Management throughout the whole migration
* Cluster Administration Service
* Cluster Installation Service
* V8 EXAcademy Upgrade Course
* V8 Release Note mentioning supported OS (RedHat Enterprise Linux, and Ubuntu 22.04.2 LTS)

Cooperation and Customer Responsibility:
* provide as needed additional resources (e.g., external Backup space, additional clusters)
* Commit to the commonly agreed project plan

For information about the Migration Service, contact your account manager.


### How do I install v8 on my own?
Installation instructions can be found on the [Exasol documentation page](https://docs.exasol.com/db/latest/home.htm). For customers who booked "Cluster Administration Service" or "Platinum Support Level", Exasol Support will take care about the installation. For all others please get in touch with your Account Manager in order to get a quote.


### How long can I use version 7.0 oder 7.1 before I have to upgrade to V8.0

You can find the EOL dates for release here: https://exasol.my.site.com/s/article/Exasol-Life-Cycle-Policy?language=en_US

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


## Deployment-specific questions

### Does Exasol V8 will become available in the Cloud marketplaces

Yes, we will publish v8 in the cloud marketplaces at a later point in time. Our primary goal is to launch V8 first on all platforms.

## Contact Support
Exasol Support can be contacted as described on this page https://exasol.my.site.com/s/?language=en_US 

