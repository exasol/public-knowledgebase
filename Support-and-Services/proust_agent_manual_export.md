# Manual Statistical Data Export for Offline Monitoring with the Exasol Cloud Monitoring Agent App

## Overview

The **Exasol Cloud Monitoring Agent App** was originally developed to run as an "online" monitoring agent within customer systems, enabling continuous monitoring and data export to Exasol's monitoring infrastructure. However, the app has been modified to support manual data export for "offline" environments, where continuous online monitoring isn't feasible. 

This article contains instructions on using the Exasol Cloud Monitoring Agent App in this offline, manual mode.

## Requirements

The Exasol Cloud Monitoring Agent App can be manually run on any machine that has network connectivity to the target Exasol database. Versions of the app are available for both Windows and Linux. Other than network connectivity, there are no additional requirements to run the app.

The app outputs data to standard output (stdout). For manual use, the output should be redirected to a text file.

## Parameters

When using the Exasol Cloud Monitoring Agent App in manual mode, the following parameters are available:

- **`-collect`**  
  A flag that instructs the agent to collect monitoring data in manual mode.

- **`-host`**  
  Specifies the host and port of the target Exasol database in the format `<DB_HOST_IP>:<DB_PORT>`.
  - `DB_HOST_IP` is the IP address of the accesible Exasol worker node.
  - `DB_PORT` is the Exasol port used for database access.
  - **Note**: Only IP addresses are currently supported. Support for hostnames will be added in future updates.

- **`-user`**  
  Exasol user login that the app will use to connect and gather statistics. The specified user should have the **"select any dictionary"** privilege.

- **`-pass`**  
  Password of the corresponding Exasol user account.

- **`-duration`**  
  Specifies the time period for which data should be exported. Currently, this parameter accepts only hours and minutes. Support for additional time units will be introduced in future updates.

## Example

Below are examples of how to run the Exasol Cloud Monitoring Agent App in offline mode on both Windows and Linux.

### Windows
```bash
./check_sqlquery.exe -collect -user <EXA_USER> -pass <EXA_USER_PASS> -host <DB_HOST_IP>:<DB_PORT> -duration 5000h > monitoring_export.line
```

### Linux
```bash
./check_sqlquery -collect -user <EXA_USER> -pass <EXA_USER_PASS> -host <DB_HOST_IP>:<DB_PORT> -duration 5000h > monitoring_export.line
```

### In both examples:

Replace <EXA_USER> and <EXA_USER_PASS> with the actual Exasol user credentials.
Replace <DB_HOST_IP> and <DB_PORT> with the actual IP and port for the Exasol instance.
The output (monitoring_export.line) will contain statistical data in InfluxDB line protocol format.

## Output

The output of the application will be a text file containing Exasol database statistical data in the InfluxDB line protocol format. After generating this file, it should be compressed into a .tar.gz archive and sent to Exasol for the further import into the monitoring system.

Example:

```bash
tar -czvf monitoring_export.tar.gz monitoring_export.line
```

## Downloads
### Linux

* [check_sqlquery](attachments/check_sqlquery.exe)

### Windows

* [check_sqlquery.exe](attachments/check_sqlquery.exe)
