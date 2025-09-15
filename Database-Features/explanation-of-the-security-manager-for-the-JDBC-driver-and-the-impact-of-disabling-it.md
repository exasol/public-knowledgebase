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

What is the security manager for the Exasol "IMPORT/EXPORT FROM/TO JDBC" commands and what are the implications of disabling it in the JDBC driver configuration?

## Answer

### Background Information

The Java Security Manager was introduced in Java 1.0.

Its primary purpose was to provide a "sandbox" for Java applets, which were small Java applications embedded in web browsers. At the time, applets were a common way to deliver dynamic content on the web. The Java Security Manager's role was to protect the user's system from potentially malicious code downloaded from the internet.

It enforced a security policy that defined what actions the untrusted applet code was allowed to perform. This included restricting access to local resources such as the file system, network connections, and system properties, preventing an applet from, for example, reading or deleting files on the user's computer without permission.

The Java Security Manager has been deprecated for removal and is now effectively disabled in modern Java versions. It was deprecated in Java 17 (JEP 411) and permanently disabled in Java 24 (JEP 486). This means that even if you try to enable it via command-line options or by calling System.setSecurityManager(), it will either be ignored or an UnsupportedOperationException will be thrown.
There were several key reasons for this change, as outlined in the JDK Enhancement Proposals (JEPs).

Despite its original purpose, the Security Manager was rarely used to secure server-side applications. It was disabled by default, and developers found it notoriously difficult to configure correctly. A slight misconfiguration could either render the security useless or, more commonly, break the application entirely. Its all-or-nothing nature made it unappealing for the nuanced security needs of modern applications.

### Changes to Java Security Manager Usage with Exasol Drivers

Setting the NOSECURITY flag to YES disables Java Security Manager, allowing function calls without additional checks.

The Java Security Manager provides detailed control over which functions are permitted to run in your environment. However, configuring these settings can be complex and time-consuming.  In the past, we tried to whitelist only the functions that JDBC drivers required. However, because the drivers frequently change and add new functions with each update, maintaining an accurate whitelist soon became impractical—especially since ExaLoader would then require a comprehensive list covering all functions for all drivers.

In the example above when the IMPORT operation tried to establish a JDBC connection, it simply hung until  one disables Security Manager. There were no exceptions providing details about the blocked class or method, so we couldn't identify anything specific to whitelist. Considering the number of third-party drivers involved and the fact that Java has deprecated the Security Manager, maintaining whitelists is not only extremely time-consuming but also often impractical—or even impossible.

As a result, Exasol no longer supports function whitelisting for drivers. This means that, for several drivers to operate correctly, it may be necessary to disable the Java Security Manager.

## Recommendation

To ensure security, always download the JDBC driver required by virtual schemas and the IMPORT command from an official and trusted source. After downloading, verify the checksum to confirm the file’s integrity and that it hasn’t been tampered with.

## References

* [JEP 486: Permanently Disable the Security Manager](https://openjdk.org/jeps/486#)
* [JEP 411: Deprecate the Security Manager for Removal](https://openjdk.org/jeps/411)
* [Intro to the Java SecurityManager](https://www.baeldung.com/java-security-manager)
* [Security Policy in Java](https://medium.com/@Shamimw/security-policy-in-java-6004f33ec036)
* [Documentation of how to Add JDBC Driver](https://docs.exasol.com/db/latest/administration/on-premise/manage_drivers/add_jdbc_driver.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
