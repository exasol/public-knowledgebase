# Scale an AWS Exasol Deployment

## Background

You need to scale an Exasol deployment up or down. Depending on the deployment, this can involve changing the EC2 instance size or the number of active data nodes. For an AsApp deployment, review the configured DB RAM after changing the EC2 instance size: the database RAM setting is separate and does not change automatically with the instance size.

- Changing EC2 instance size changes the hardware available to a node.
- Adding active data nodes changes database processing capacity. Reserve nodes provide failover capacity, not additional processing capacity while they remain reserved.
- Changing DB RAM changes the memory configured for the database. It does not change EC2 instance size or node count, but may be a follow-up step when scaling an AsApp deployment.

## Prerequisites

- Confirm which of the three changes you need and check the documentation for your installed Exasol version and deployment type.
- For DB RAM changes, determine a suitable value for your data and workload before scheduling the database stop.
- For node-count or instance-size changes, plan and validate a backup before making infrastructure changes.

## Scale the deployment

### Step 1

Identify whether you need to change EC2 instance size or active data-node count. After changing the instance size in an AsApp deployment, review DB RAM and adjust it if needed.

### Step 2

To add active data nodes, use the procedure for [adding and activating data nodes](https://docs.exasol.com/db/latest/administration/on-premise/nodes/add_activate_datanodes.htm) that matches your Exasol version and deployment.

To add failover capacity, use the version-appropriate [reserve-node procedure](https://docs.exasol.com/db/latest/administration/on-premise/nodes/reserve_nodes/add_reserve_nodes_existing.htm). Reserve nodes do not add processing capacity while reserved.

### Step 3

Active nodes cannot be removed from an existing Exasol database. To run with fewer active nodes, create a new deployment with the desired node count and migrate the database using a validated backup and restore. Confirm the supported migration procedure for your Exasol version before proceeding.

### Step 4

For an AsApp deployment running on AWS, change the EC2 instance type manually in AWS. Do not use `confd_client infra_db_scale`: AsApp host deployments reject this and most other ConfD infrastructure jobs. The database must be stopped before modifying the instance. Confirm the target instance's CPU, memory, and storage, and that the deployment's storage layout remains available. Follow the AWS and Exasol procedure for your deployment before proceeding.

This tutorial does not specify the manual EC2 resize sequence. Confirm the steps for the target AWS configuration and installed Exasol version before proceeding.

### Review and adjust DB RAM

After changing the instance size in an AsApp deployment, review the configured DB RAM because it does not change automatically with the EC2 instance size. With a Raw Data license, the license limit is based on raw data size, not configured DB RAM. Choose a DB RAM value that fits the workload and available instance memory; see the [Exasol sizing guidelines](https://docs.exasol.com/db/latest/administration/on-premise/sizing.htm).

Execution context: **Host**. Replace `<PLAY_ID>`, `<DB_NAME>`, and `<DB_RAM>` with the deployment ID, database name, and reviewed RAM value.

Connect to COS:

```shell
c4 connect -i <PLAY_ID> -s cos
```

Execution context: **COS**.

Find the database and check its current configured RAM:

```shell
confd_client db_list
confd_client db_info db_name: <DB_NAME> | grep mem_size
```

Stop the database, set the new value, and start it again:

```shell
confd_client db_stop db_name: <DB_NAME>
confd_client db_configure db_name: <DB_NAME> mem_size: '<DB_RAM>'
confd_client db_start db_name: <DB_NAME>
```

Schedule an outage for the stop and start. `mem_size` accepts a value in MiB, GiB, or TiB. Reducing DB RAM limits memory available to the database process; it does not reduce physical RAM on the EC2 instances.

## Additional Notes

After a change, confirm the database starts and is connectable. For a DB RAM change, verify the configured `mem_size` and monitor workload performance.

Contact Exasol Support if the version-specific procedure, storage layout, migration plan, or expected downtime is unclear.

AsApp infrastructure-job behavior and manual EC2 resizing depend on the target deployment and Exasol version.

## Additional References

- [ConfD `db_configure` job](https://docs.exasol.com/db/latest/confd/jobs/db_configure.htm)
- [Exasol licensing](https://docs.exasol.com/db/latest/planning/licensing.htm)
- [ConfD infrastructure jobs restricted on AsApp](https://docs.exasol.com/db/latest/changelogs/22167.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
