# SLA Uptime Calculation

The definition of up-time is defined as "The time on which the database is available for logins, accepting connections, available for read and write operations".

The time is calculating by pulling information from EXA_SYSTEM_EVENTS table values:

- Event type: Startup (up-time)

- Event type: Shutdown (downtime) 

For scheduled maintenance tasks, the up-time must be recalculated as this scheduled maintenance will be shown as event type "Shutdown".

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 