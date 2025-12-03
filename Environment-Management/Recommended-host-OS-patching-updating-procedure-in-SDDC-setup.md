# Recommended host OS patching and updating procedure in SDDC setup

## Background

In SDDC setup, you are looking for the best approach for patching and updating their RHEL host OS, while making sure that the database service is available.

## Prerequisites

Exasol 8 runs in SDDC setup.

## How to apply host OS patch/update in SDDC setup

### Step 1

Update each host system while it is active.

### Step 2

If the host systems needs to be restarted, stop the database first, restart all hosts, and then start the database again.

## Additional Notes

You may think of patching the host OS on the inactive half of SDDC, anticipating that it should not impact the availability of the DB, then they would switch SDDC over, to patch the host OS on the remaining side of SDDC. But Exasol opposes this approach because of the following reason.

Updating the host systems on the inactive half of SDDC, then switch SDDC over to patch the host OS on the remaining side of SDDC should theoretically work. However, it carries a risk of data loss due to the role of the inactive half of the cluster as storage redundancy.

If a node is being updated or restarted and is unavailable at the same time the active node (which relies on it for redundancy) experiences a storage failure, data loss could occur.

While backups may allow for recovery, the resulting database downtime would likely be even longer. This is a risk which Exaslo and you may not want to take. Therefore Exasol does not recommend to the procedure of patching inactive SDDC site first then switch over SDDC to patch the rest.

## Additional References

[Synchronous dual data center](https://docs.exasol.com/db/latest/planning/business_continuity/sddc_details.htm)
