# Explanation of the Security Manager for the JDBC Driver and the Impact of Disabling It

## Question

You can disable the Security Manager by setting NOSECURITY=YES in the JDBC driver configuration, as shown in the following example:

```text
DRIVERNAME=MSSQLServer
PREFIX=jdbc:sqlserver:
FETCHSIZE=100000
INSERTSIZE=-1
NOSECURITY=YES
```

What is the security manager for the Exasol JDBC driver and what are the implications of disabling it in the JDBC driver configuration?

## Answer

Setting the NOSECURITY flag to YES disables security manager, allowing function calls without additional checks.

The Security Manager provides detailed control over which functions are permitted to run in your environment. However, configuring these settings can be complex and time-consuming.  In the past, we tried to whitelist only the functions that JDBC drivers required. However, because the drivers frequently change and add new functions with each update, maintaining an accurate whitelist soon became impractical—especially since ExaLoader would then require a comprehensive list covering all functions for all drivers.

As a result, Exasol no longer supports function whitelisting for drivers. This means that, for several drivers to operate correctly, it may be necessary to disable the security manager.

## Recommendation

To ensure security, always download the Exasol JDBC driver from an official and trusted source. After downloading, verify the checksum to confirm the file’s integrity and that it hasn’t been tampered with.

We also recommend building security directly into your applications from the start, instead of relying only on external security managers.

### Further Background Information

The Java Security Manager has been deprecated for removal and is now effectively disabled in modern Java versions. It was deprecated in Java 17 (JEP 411) and permanently disabled in Java 24 (JEP 486). This means that even if you try to enable it via command-line options or by calling System.setSecurityManager(), it will either be ignored or an UnsupportedOperationException will be thrown.
There were several key reasons for this change, as outlined in the JDK Enhancement Proposals (JEPs).

Despite its original purpose, the Security Manager was rarely used to secure server-side applications. It was disabled by default, and developers found it notoriously difficult to configure correctly. A slight misconfiguration could either render the security useless or, more commonly, break the application entirely. Its all-or-nothing nature made it unappealing for the nuanced security needs of modern applications.

## References

* [JEP 486: Permanently Disable the Security Manager](https://openjdk.org/jeps/486#:~:text=Summary,via%20JEP%20411%20(2021).)
* [Documentation of how to Add JDBC Driver](https://docs.exasol.com/db/latest/administration/on-premise/manage_drivers/add_jdbc_driver.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
