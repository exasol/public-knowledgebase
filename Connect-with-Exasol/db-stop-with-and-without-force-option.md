# DB Stop with and without Force Option

## Question

* What is the difference between a database stop with and without force?
* What happens during a database stop with open transactions?

## Answer

### Normal Shutdown

Example command:

```shell
confd_client db_stop db_name: DB1
```

A normal shutdown in Exasol is a controlled, graceful termination of database services, which proceeds in multiple steps over a grace period.

#### Key Consequences and Usage of Normal Shutdown

* **Transaction Handling:** It aborts all active transactions and queries using the standard mechanism (like session kill). If necessary, transactions are forcefully terminated after a short grace period.

* **Duration:** The entire duration is variable and depends on the system size, often taking several minutes for larger systems to allow all service processes to follow their own clean shutdown logic.

* **New Connections:** No new connections are accepted during the process; they are rejected with a specific SQL exception.

* **Impact:** The process includes flushing system statistics and writing a corresponding shutdown record to the auditing tables. This provides a clear audit trail.

### Forced Shutdown

Example command:

```text
confd_client db_stop db_name: DB1 force: true
```

A forced shutdown in Exasol is an immediate and abrupt termination of all active database connections and service processes.

#### Key Consequences and Usage of Forced Shutdown

* **Impact:** Because the termination is so abrupt, no entry is written to the auditing table, making the event functionally equivalent to a complete system crash.

* **When to Use:** ⚠ This process should be used **only as a last resort** when a critical issue prevents a normal shutdown.⚠ Examples include a bug or a system malfunction that stops the database from shutting down cleanly.

### Behavior of Uncommitted Transactions During Database Shutdown

In Exasol, uncommitted changes remain isolated within their respective transactions and are never visible to other sessions. When a database shutdown is initiated with force: false (the standard behavior), the database automatically performs a rollback of any open, uncommitted transactions before the shutdown completes. This ensures that no changes are persisted or exposed beyond their transaction scope.
If a transaction ends or disappears before committing—such as during a normal shutdown or a query crash—no explicit user intervention is required, as the database handles the rollback process internally. As a result, all uncommitted modifications are safely discarded during shutdown, maintaining data integrity.

## References

* [Documentation of ConfD | db_stop](https://docs.exasol.com/db/latest/confd/jobs/db_stop.htm)
* [Documentation of Stop a Database](https://docs.exasol.com/db/latest/administration/on-premise/manage_database/stop_db.htm)
* [Documentation of Transaction Management](https://docs.exasol.com/db/latest/database_concepts/transaction_management.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
