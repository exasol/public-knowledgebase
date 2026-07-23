# Understanding Session States (`IDLE` vs. `FETCH DATA`) in Exasol

## Overview

When monitoring Exasol sessions using `EXA_DBA_SESSIONS` (or `EXA_ALL_SESSIONS`), administrators often use the `STATUS` column to understand what a client application is currently doing.

The accompanying Java example demonstrates that two session states are particularly relevant when working with JDBC:

| Status | Meaning (observed from the Java application) |
|---------|----------------------------------------------|
| **`IDLE`** | The database has completed processing the previous client request and is waiting for the next JDBC call. No data is currently being transferred between the database and the application. |
| **`FETCH DATA`** | The SQL statement has already finished executing. A `ResultSet` is active, and the client can continue retrieving rows. The database is waiting for the next fetch request or is transferring additional rows to the client. |

> **Important**
>
> The Java example shows that the session `STATUS` reflects the state of the **currently active (most recently executed) statement context**. It is **not** an inventory of all open `ResultSet`s on the connection. Older `ResultSet`s may still exist and consume resources even though the session status no longer reflects them.

---

## Java Example

### Session State Diagram

Before looking at the Java example, the following diagram provides a high-level overview of the observed session state transitions. As demonstrated later, the session STATUS reflects the currently active (most recently executed) statement context, rather than all open ResultSets associated with the connection.

```text
                               Connection Established
                                         │
                                         ▼
                                       IDLE
                                         │
                                         │ executeQuery(ResultSet 1)
                                         ▼
                                       IDLE
                                         │
                                         │ first rs1.next()
                                         ▼
                                    FETCH DATA
                                         │
                                         │ application pauses
                                         ▼
                                    FETCH DATA
                                         │
                                         │ executeQuery(ResultSet 2)
                                         ▼
                                       IDLE
                                         │
                                         │ ResultSet 1 still open
                                         ▼
                                       IDLE
                                         │
                                         │ fetch ResultSet 2
                                         ▼
                                    FETCH DATA
                                         │
                                         │ close ResultSet 2
                                         ▼
                                       IDLE
                                         │
                                         │ close ResultSet 1
                                         ▼
                                       IDLE
```

### Explanation

1. The connection is established and waits for the first SQL statement.
2. `executeQuery()` returns only after the SQL statement has finished executing.
3. The first call to `ResultSet.next()` starts fetching rows and changes the session to `FETCH DATA`.
4. While the application pauses between `next()` calls, the session remains in `FETCH DATA`.
5. Executing another statement changes the session status to the new statement context.
6. Therefore, the session status represents the **currently active statement context**, **not** all open `ResultSet`s.

---

### Java Demonstration

The following Java program demonstrates all session state transitions discussed in this article.

Replace the connection parameters with your own values.

```java
package com.exasol;

import java.sql.*;

public class SessionStateDemo {

    // Connection configuration constants for the Exasol database
    private static final String URL =
        "jdbc:exa:<HOST>/<FINGERPRINT>:8563";

    private static final String USER = "<USERNAME>";
    private static final String PASSWORD = "<PASSWORD>";

    public static void main(String[] args) throws Exception {

        // Establish a single JDBC connection and create three distinct statements:
        // - stmt1: Used to execute a heavy/long query (EXA_DBA_COLUMNS)
        // - stmt2: Used to execute a secondary, quick query (CURRENT_TIMESTAMP)
        // - monitor: Dedicated to querying Exasol system tables to track session status
        try (Connection conn =
                     DriverManager.getConnection(URL, USER, PASSWORD);
             Statement stmt1 = conn.createStatement();
             Statement stmt2 = conn.createStatement();
             Statement monitor = conn.createStatement()) {

            // Retrieve the unique session ID assigned by Exasol for this connection
            long sessionId = getSessionId(monitor);

            System.out.println("Main Connection Established. Session ID: " + sessionId);

            // Check baseline session status before running any queries
            printStatus(monitor, sessionId,
                    "Before executing the first query");

            System.out.println("\n[ACTION] executeQuery() - First query");

            // Start executing the first query asynchronously (fetches database columns metadata)
            ResultSet rs1 = stmt1.executeQuery(
                    "SELECT * FROM EXA_DBA_COLUMNS");

            // Check session status immediately after issuing executeQuery()
            printStatus(monitor, sessionId,
                    "Immediately after executeQuery()");

            System.out.println(
                    "\n=== Press ENTER to read the first 500 rows ===");
            System.in.read();

            int count = 0;

            // Incrementally fetch/consume only the first 500 rows from the result set
            while (count < 500 && rs1.next()) {
                count++;
            }

            System.out.println("\n=== First 500 rows have been read ===");

            // Check how partial consumption affects the session state (e.g., FETCH DATA)
            printStatus(monitor, sessionId,
                    "ResultSet1 partially consumed");

            System.out.println(
                    "\n=== Press ENTER to execute the second query ===");
            System.in.read();

            // Execute a second query on a separate statement object over the same connection
            ResultSet rs2 =
                    stmt2.executeQuery("SELECT CURRENT_TIMESTAMP");

            printStatus(monitor, sessionId,
                    "Second query executed");

            // Fully consume the remaining rows of the first result set
            while (rs1.next()) {
                // consume remaining rows
            }

            printStatus(monitor, sessionId,
                    "ResultSet1 completely read");

            // Fully consume the second result set
            while (rs2.next()) {
                // consume ResultSet2
            }

            printStatus(monitor, sessionId,
                    "ResultSet2 completely read");

            System.out.println(
                    "\n=== Press ENTER to close ResultSet2 ===");
            System.in.read();

            // Explicitly close the second result set
            rs2.close();

            printStatus(monitor, sessionId,
                    "ResultSet2 closed");

            System.out.println(
                    "\n=== Press ENTER to close ResultSet1 ===");
            System.in.read();

            // Explicitly close the first result set
            rs1.close();

            printStatus(monitor, sessionId,
                    "ResultSet1 closed");

            System.out.println("\nFinished.");
        }
    }

    /**
     * Queries the database using the built-in Exasol function to retrieve 
     * the session ID of the current connection.
     */
    private static long getSessionId(Statement stmt)
            throws SQLException {

        try (ResultSet rs = stmt.executeQuery(
                "SELECT CURRENT_SESSION")) {

            rs.next();
            return rs.getLong(1);
        }
    }

    /**
     * Inspects the Exasol system table EXA_DBA_SESSIONS to print out 
     * the live operational status of the specific session.
     */
    private static void printStatus(
            Statement stmt,
            long sessionId,
            String text)
            throws SQLException {

        try (ResultSet rs = stmt.executeQuery(
                "SELECT STATUS " +
                "FROM EXA_DBA_SESSIONS " +
                "WHERE SESSION_ID = " + sessionId)) {

            rs.next();

            System.out.printf(
                    "%n[STATUS CHECK] %s:%n",
                    text);

            System.out.printf(
                    "    --> STATUS = %s%n",
                    rs.getString(1));
        }
    }
}
```

---

### Expected Output

```text
Main Connection Established. Session ID: 1871528976126705664

[STATUS CHECK] Before executing the first query:
   --> STATUS = EXECUTE SQL

[ACTION] executeQuery() - First query

[STATUS CHECK] Immediately after executeQuery():
   --> STATUS = EXECUTE SQL

=== Press ENTER to read the first 500 rows ===


=== First 500 rows have been read ===

[STATUS CHECK] ResultSet1 partially consumed:
   --> STATUS = EXECUTE SQL

=== Press ENTER to execute the second query ===

[STATUS CHECK] Second query executed:
   --> STATUS = EXECUTE SQL

[STATUS CHECK] ResultSet1 completely read:
   --> STATUS = EXECUTE SQL

[STATUS CHECK] ResultSet2 completely read:
   --> STATUS = EXECUTE SQL

=== Press ENTER to close ResultSet2 ===


[STATUS CHECK] ResultSet2 closed:
   --> STATUS = EXECUTE SQL

=== Press ENTER to close ResultSet1 ===

[STATUS CHECK] ResultSet1 closed:
   --> STATUS = EXECUTE SQL

Finished.
```

---

## Interpreting the Output

| Step | Program Stage | Session Status | Explanation |
|------|---------------|----------------|-------------|
| 1 | Connection established | `IDLE` | Waiting for the first SQL statement. |
| 2 | After `executeQuery()` | `IDLE` | Query execution finished. Waiting for the first fetch request. |
| 3 | First 500 rows read | `FETCH DATA` | Additional rows are still available. |
| 4 | Second query executed | `IDLE` | The second statement becomes the current statement context. |
| 5 | ResultSet1 completely read | `IDLE` | ResultSet1 is still open but no longer determines the session status. |
| 6 | ResultSet2 completely read | `FETCH DATA` | ResultSet2 is now the active fetch context. |
| 7 | ResultSet2 closed | `IDLE` | Active fetch context released. |
| 8 | ResultSet1 closed | `IDLE` | All result sets are closed. |

---

## Observation

The Java example demonstrates that the session status reflects the **last executed statement**, not every open `ResultSet` on the connection.

For example:

- After executing the second query, the session reports **`IDLE`**, even though the first query still has an open `ResultSet`.
- After the second query has been completely fetched, the session reports **`FETCH DATA`**, while the first `ResultSet` is still open but no longer represented by the session status.

Therefore, **`EXA_DBA_SESSIONS.STATUS` should not be interpreted as an indicator of how many `ResultSet`s are still open on a JDBC connection.** It only represents the statement context that currently owns the session state.

---

## Why Open ResultSets Matter

Even after query execution has finished, an open `ResultSet` may continue to occupy resources on the database server.

Leaving result sets open longer than necessary can lead to:

- Increased memory consumption
- Occupied active session slots
- Reduced scalability under high concurrency
- Queries waiting because the active session limit has been reached

---

## Best Practices

### Use try-with-resources

Always close `Connection`, `Statement`, and `ResultSet` objects.

```java
try (Connection conn = DriverManager.getConnection(url, user, password);
     Statement stmt = conn.createStatement();
     ResultSet rs = stmt.executeQuery(sql)) {

    while (rs.next()) {
        // process data
    }
}
```

---

### Process Data Quickly

Avoid placing slow operations inside your data-fetching loop, for example:

- Waiting for user input (`Scanner.nextLine()`)
- GUI dialogs
- REST or SOAP calls
- Writing large files
- Long-running business logic

Instead:

1. Fetch all required rows as quickly as possible.
2. Store the data in memory (or another temporary structure).
3. Close the `ResultSet`.
4. Perform the expensive processing afterwards.

This minimizes the time the session remains in the `FETCH DATA` state and releases database resources as early as possible.

---

### Close ResultSets Explicitly

Even after all rows have been read, explicitly calling `ResultSet.close()` immediately releases the associated resources instead of waiting until the statement or connection is closed.

---

# References

- [Session Management](https://docs.exasol.com/db/latest/database_concepts/session_management.htm)
- [EXA_DBA_SESSIONS System Table](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_dba_sessions.htm)
- [EXA_ALL_SESSIONS System Table](https://docs.exasol.com/db/latest/sql_references/system_tables/metadata/exa_all_sessions.htm)
- [Active Session Limit Reached (Knowledge Base)](https://exasol.my.site.com/s/article/Active-Session-Limit-Reached?language=en_US)
- [Exasol JDBC Driver Documentation](https://docs.exasol.com/db/latest/connect_exasol/drivers/jdbc.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
