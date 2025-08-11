# Which ticket priorities does Exasol use?

When you create a ticket, you should select the following criteria:

- Impact
- Urgency

## Mapping to Exasol priorities

Exasol determines the priority of incidents by analyzing the combination of selected "Impact" and "Urgency" factors. "Impact" reflects the extent of consequences, categorized as "System-Wide", affecting "Multiple-Users", or a "Single-User". Meanwhile, "Urgency" specifies how quickly a resolution is necessary, categorized as High, Medium, or Low. Based on the selected combination the priorities are set.

## Critical (Blocker)

Business-critical processes are no longer available. No quick, temporary solution exists.
Important note: If you have to create a ticket with a critical priority outside of German business hours (CEST time), you must [call our support hotline as well](https://exasol.my.site.com/s/create-new-case?language=en_US).

Examples:

- The connection to the database is not possible and/or often sporadically interrupted (restarting), or the database service is not available
- The database does not start due any disk space issue
- The database does not start after an update
- The VPN Tunnel does not function, and a database connection is therefore not possible

## Major

Important functions and/or access to the database are severely compromised. Working with the database is only possible to a limited extent.

Examples:

- Backup processes lead to a loss of performance
- Database memory overflow
- Database requests (Queries) significantly slower after a version update

## Normal

Does not apply to critical business processes but has an operational impact. No direct impact on the database availability. A temporary solution is possible.

Examples:

- Database requests (Queries) fail with an Error, but there is no direct impact on the general availability of the database
- Transaction errors
- A database server error leads to a loss of cluster redundancy

## Minor

An error that has no or only minimal effects, or other minor disruptions or impairments, product questions.
No impact on business processes.

Examples:

- Planned activities: Migrations, version updates, firmware update
- Questions regarding products and functions
- Installations and consulting

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*

