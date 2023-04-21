# Database connection encryption at Exasol 
### Background

This article will explain about the details on encryption at Exasol Database.

It gives you answers for questions like :

Is data transfer through client connection encrypted by default or not?

How to check encryption is enabled in database?

How to enable/disable encryption?

What is the parameter forceProtocolEncryption used for?

How to enforce encrypted client connections ? and so on ...

### Explanation

In Exasol database, when data is transferred through a network, the data is by default encrypted (from Exasol versions 6.0 and above). Until version 7.0, Exasol used ChaCha20 encryption for JDBC, ODBC, ADO.NET, CLI and for WebSockets, Exasol used TLS v 1.2 encryption. However, starting from version 7.1 Exasol uses TLS encryption for JDBC, ODBC, ADO.NET, WebSockets and for CLI.

On all clients and drivers, the encryption can be enabled by using their respective connection string parameters, for example:

* EXAPlus: -encryption <ON|OFF>
* JDBC: encryption=<1|0> (1 = on, 0= off, default is 1)
* ODBC: ENCRYPTION=<"Y"|"N"> (Y is default)
* ADO.NET: encryption=<ON|OFF> (on is default)

### How to check if data transferred was encrypted or not:

One can check the ‘encrypted’ column in exa_dba_sessions or exa_dba_audit_sessions tables that encryption was set to true or false for that particular session.

### The Parameter *forceProtocolEncryption*:

In addition to these driver properties, one can set a database parameter in EXAoperation to force incoming connections to be encrypted. The parameter is: -forceProtocolEncryption=1. This can be done while creating a database or setting it in Exaoperation and restarting the database again.

#### Further Clarifications:

Prior to Exasol version 7.1, if the parameter '-forceProtocolEncryption=1' is set to the database, it means that regardless of what the client requests, protocol encryption will be FORCED (i.e. required) by Exasol for the connection. If either Exasol or the client requests encryption, encryption will be used. Therefore if the parameter '-forceProtocolEncryption=1' is set over the database, then all the connections are encrypted, for versions before 7.1.  
But starting Exasol drivers version 7.1, if this parameter is set and if at the client side the encryption is set to OFF or 0, then you will get an error like below while connecting:

"Illegal encryption settings: server requires encryption but the user has turned encryption off."

#### Additional notes:

Prior to version 7.1:

With '-forceProtocolEncryption=1', clients are only rejected if they do not support encryption at all (e.g. older drivers).  
An unencrypted connection is only allowed if both Exasol and the client disable encryption.

Having this parameter (forceProtocolEncryption=1) set, means that even if the client/driver side encryption is turned off then (with the exception of -- the driver being not old/does not support encryption) then the client/driver is forced to encrypt data. In other case (when this parameter would not have been set) then client/driver connection would be allowed to transfer data UNENCRYPTED. NOTE: One can check the ENCRYPTED column from the EXA_DBA_SESSIONS table and confirm if it is true or false in such a case.

Starting from version 7.1:

However, the above paragraph (prior to version 7.1) stands not entirely true for Exasol version 7.1 and above. If the client side the encryption is set to FALSE, then the connection error is produced, if the parameter is set for the database. Hence this case, only an encrypted connection is allowed. 

#### Additional references:

<https://docs.exasol.com/planning/data_security.htm#GeneralConcepts>

<https://docs.exasol.com/sql_references/metadata/metadata_system_tables.htm>

Bug related to this topic: [EXASOL-2649](https://www.exasol.com/support/browse/EXASOL-2649)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 