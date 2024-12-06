# Generating TLS files yourself to avoid providing a fingerprint

## Background

The article is devoted to configuring access to an Exasol database using the latest Exasol drivers, but without using a fingerprint.

The concept of using and uploading TLS certificates to an Exasol cluster is explained in the following documentation pages:

* [Upload TLS Certificate, version 8](https://docs.exasol.com/db/latest/administration/on-premise/access_management/tls_certificate.htm)
* [Upload TLS Certificate, version 7.1](https://docs.exasol.com/db/7.1/administration/on-premise/access_management/tls_certificate.htm)

The description of the TLS encryption feature could be found in the following changelog entry: [CHANGELOG: TLS for all Exasol drivers](https://exasol.my.site.com/s/article/Changelog-content-6507?language=en_US).

Our github repository "Exasol Java tutorial" also contains two articles explaining the overall concept and relation to Exasol:

* [An Introduction to TLS](https://github.com/exasol/exasol-java-tutorial/blob/main/tls-tutorial/doc/tls_introduction.md)
* [TLS With Exasol](https://github.com/exasol/exasol-java-tutorial/blob/main/tls-tutorial/doc/tls_with_exasol.md)

Please acquaint yourself with the process of using and uploading TLS certificates for your database version, as well as with the description of the TLS encryption feature, using the links above.

The tutorial applies to a particular use case:

1. Only a connection string with IP addresses or DNS names could be used, fingerprint couldn't be added.
2. Customer's IT Department or Security Department couldn't purchase a certificate from a public certification authority (CA) and also couldn't generate certificate in-house and sign it with company's customr root CA certificate.

__If both items hold__, than the last resort will be to generate yourself

1. A root CA certificate and key.
2. A server certificate singed by the root CA certificate above, and a key.

and add them to

1. Exasol cluster.
2. Client application truststores.

## Prerequisites

* An environment with `openssl` utility, to generate the certificates / keys.
* Administrative access to ConfD in case of DB version 8 (see [ConfD](https://docs.exasol.com/db/latest/confd/confd.htm)) or EXAoperation ([EXAoperation](https://docs.exasol.com/db/7.1/administration/on-premise/admin_interface/exaoperation.htm)), to upload the files to Exasol cluster.
* Sufficient access on client machines to make changes to respective truststores (see below).

## How to generate TLS files

All settings here could be hardened by customer if needed by customer's security policies.

File names could also be changed when needed, but in a coordinated way as some commands depend on files generated on the previous steps.

We'll be listing commands and describe the output.

Full explanation of `openssl` utility parameters could be found in `openssl` documentation: [OpenSSL commands](https://docs.openssl.org/master/man1/).

```shell
# Generate CA key
openssl genrsa -out rootCA_key.pem 4096
```

This command creates file `rootCA_key.pem`. Its content is sensitive and should be accessible by a limited subset of administrative users.

```shell
# Create CA cert
openssl req -x509 -new -nodes -key rootCA_key.pem -sha256 -days 3650 -out rootCA_cert.pem -subj '/CN=Custom_root_CA_for_Exasol_databases/O=test/C=DE'
```

This command creates a CA certificate as file `rootCA_cert.pem` with the following settings

* Valid for 10 years (`-days 3650`).
* The key is not password protected (`-nodes`)
* Common name (`CN` in `-subj`) is "Custom root CA for Exasol databases"
* Organization Name (`O` in `-subj`) is "test"
* Country Name (`C` in `-subj`) is "test"

This file is not sensitive.

```shell
# Create server key
openssl genrsa -out server_key.pem 4096
```

This command creates file `server_key.pem`. Its content is sensitive and should be accessible by a limited subset of administrative users.

```shell
# Generate server cert signing request
openssl req -new -sha256 -key server_key.pem -subj "/CN=CLUSTER_DNS_NAME_SOME_DESCRIPTIVE_NAME" -out server_cert.csr
```

This command creates file `server_cert.csr`. It isn't sensitive and at the same time, it's just an intermediate file needed for further steps. This file corresponds to the Common Name (CN): "CLUSTER_DNS_NAME_SOME_DESCRIPTIVE_NAME". If cluster is accessed by SQL clients via DNS name like exadev.companyname.com, one could simply put this DNS name here. If that's not the case, one can put here some brief definition like "MY_COMPANY_NAME_LLC_EXASOL_DEV".

```shell
# Create cert extension file (for names/IPs not in CN)
printf "
subjectAltName = @alt_names
[alt_names]
IP.1 = 10.36.1.4
IP.2 = 10.36.1.6
IP.3 = 10.36.1.7
" > server_cert.ext
```

This command creates file `server_cert.ext`. It isn't sensitive and at the same time, it's just an intermediate file needed for further steps. All IP addresses and DNS names that are directly used in connection string in SQL client should be present in this file. In case EXAoperation is used, its IP or DNS that is used for web browser access should included into the file. IP addresses are added added as IP.1, IP.2 etc. and DNS names are added as DNS.1, DNS.2 etc. 

```shell
# Create server cert
openssl x509 -req -in server_cert.csr -CA rootCA_cert.pem -CAkey rootCA_key.pem -CAcreateserial -out server_cert.pem -days 3650 -sha256 -extfile server_cert.ext
```

This command finally creates server certificate file `server_cert.pem`. This file is not sensitive.

We are done with certificate generation. Next one needs to create a certificate chain file by concatenating files `server_cert.pem` and `rootCA_cert.pem`

```shell
cat server_cert.pem > cert_chain.pem; cat rootCA_cert.pem >> cert_chain.pem
```

and uploading the resulting certificate chain file `cert_chain.pem` and key file `server_key.pem` via respective database interfaces.

## Configuration of selected client applications

In this section we'll show how to configure some client tools to work with the certificates we've just created.
One needs to do so as the generated root CA certificate is not known to client applications.

### DBeaver, DB Visualizer and other third party tools using Exasol JDBC driver

Third party SQL clients leveraging Exasol JDBC driver typically come with their own JRE (Java Runtime Environment).
By design Java applications use their own truststore and check if they trust database certificates by searching it in such a truststore.
For example, as of 2024-11-25 for DBeaver (steps and paths for DB Visualizer are similar) JRE resides in `jre` subfolder of installation folder.
The respective truststore is `.\jre\lib\security\cacerts`.

If we want to add a certificate to DBeaver's truststore, we need to find its location and perform the activity using the standard Java tool called `keytool`.

First, we need to find the path to DBeaver executable, for me it's `<Desktop folder>\Distribs\dbeaver\dbeaver.exe` and, therefore, truststore is the file

```
<Desktop folder>\Distribs\dbeaver\jre\lib\security\cacerts
```

We need to use `keytool` utility (available in the JRE shipped by the tool) with `-import` option

```shell
keytool -import -alias exa_custom_root_ca -noprompt -storepass changeit -file rootCA_cert.pem -keystore <Desktop folder>\Distribs\dbeaver\jre\lib\security\cacerts
```

* The provided `-alias` value show be descriptive enough so that you'll understand later what this record about.
* `-file` is the name and/or absolute path to the custom root CA certificate that we've generated earlier.
* `-keystore` value should point to the truststore of the Java used by the respective client application.

After a DBeaver restart connection to DB should be possible without a fingerprint.

### EXAplus on Windows

According to [CHANGELOG: EXAplus on Windows will use Java from the current console](https://exasol.my.site.com/s/article/Changelog-content-18724?language=en_US) since version 24.0.0 EXAplus on Windows
uses the Java interpreter set in the PATH variable of the console where it is started. We will be referring to this scenario.

As EXAplus uses Exasol JDBC driver we simply need to perform the same steps as in the section "DBeaver, DB Visualizer and other third party tools using Exasol JDBC driver" but for the right Java.

As explained above, that would be Java contained in the PATH variable of the console where it is started. If you still couldn't find it,
try running EXAplus and checking using your favourite Task Manager application on Windows the list of running processes while EXAplus is still open.
For me `exaplusx64.exe` started a child `java.exe` process from "C:\Program Files\Java\jdk-21\bin\java.exe", so "C:\Program Files\Java\jdk-21\" is the Java used with its trustore residing being file `.\lib\security\cacerts` in it.

As a result, one needs to add (import) the custom root CA certificate to this truststore using Java's `keytool` utility (available, for example as file `.\bin\keytool.exe` file inside Java folder).

### ODBC driver on Windows

ODBC drivers check server certificates against the list of certificates trusted by the operating system.

Adding a certificate to Windows truststore is relatively easy - rename it to extension .crt (like "rootCA_cert.crt") and double click it.
A respective Windows wizard will open. Please choose later on if you want to add the custom root CA to Local Machine (might require administrator access) or only for Current User.
On the next step let Windows "Automatically select the certificate store based on type of certificate".

Afterwards, ODBC connection on this machine / respectively for this user should be possible without a fingerprint.

### ODBC driver on Linux

ODBC drivers check server certificates against the list of certificates trusted by the operating system.

Approach to adding a certificate to OS truststore on Linux depends on Linux distribution.

In particular, one could follow the following the steps official Linux distribution pages like

* Ubuntu: [Install a root CA certificate in the trust store](https://ubuntu.com/server/docs/install-a-root-ca-certificate-in-the-trust-store)
* Red Hat 8: [Using shared system certificates](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/8/html/securing_networks/using-shared-system-certificates_securing-networks)

Just like with other driver setups, one needs to add the generated custom root CA certificate from file "rootCA_cert.pem" following a relevant instruction for 

### ADO.NET driver on Windows

Exasol ADO.NET driver is available for Windows and as Exasol ODBC driver it checks server certificates against the list of certificates trusted by the operating system.

Therefore, please follow the approach from the section "ODBC driver on Windows".

## Additional References

* [Upload TLS Certificate, version 8](https://docs.exasol.com/db/latest/administration/on-premise/access_management/tls_certificate.htm)

* [Upload TLS Certificate, version 7.1](https://docs.exasol.com/db/7.1/administration/on-premise/access_management/tls_certificate.htm)

* [CHANGELOG: TLS for all Exasol drivers](https://exasol.my.site.com/s/article/Changelog-content-6507?language=en_US)

* [An Introduction to TLS](https://github.com/exasol/exasol-java-tutorial/blob/main/tls-tutorial/doc/tls_introduction.md)

* [TLS With Exasol](https://github.com/exasol/exasol-java-tutorial/blob/main/tls-tutorial/doc/tls_with_exasol.md)

* [ConfD](https://docs.exasol.com/db/latest/confd/confd.htm)

* [EXAoperation](https://docs.exasol.com/db/7.1/administration/on-premise/admin_interface/exaoperation.htm)

* [OpenSSL commands](https://docs.openssl.org/master/man1/)

* ["keytool" utility documentation](https://docs.oracle.com/javase/8/docs/technotes/tools/unix/keytool.html)

* [CHANGELOG: EXAplus on Windows will use Java from the current console](https://exasol.my.site.com/s/article/Changelog-content-18724?language=en_US)

* Ubuntu: [Install a root CA certificate in the trust store](https://ubuntu.com/server/docs/install-a-root-ca-certificate-in-the-trust-store)

* Red Hat 8: [Using shared system certificates](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/8/html/securing_networks/using-shared-system-certificates_securing-networks)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 
