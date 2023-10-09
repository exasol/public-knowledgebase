# PowerBI Encryption/Fingerprint Issue in Exasol 7.1

## Question
Since 7.1 there is the standard encryption/fingerprint setting in the exasol driver, when trying to set this in the PowerBI dialog for an Exasol datasource...
 
```
{"server":"XXX.XX.XX.XX..XX:8563\/9CXXXXXXXXXXXXXXXXXX80","encrypted":"Yes"}
```
 
this gives errors:
 
```
ODBC: ERROR [08055] [EXASOL][EXASolution driver]Illegal character (47) in connection string at position 23. ERROR [08055] [EXASOL][EXASolution driver]
Illegal character (47) in connection string at position 23.
```
 
Using the ODBC driver option does work, but this breaks all connections in existing reports.
Any ideas on how to solve this?

## Answer
I succeeded in reproducing your problem and succeeded in solving it in the following way:

The first thing you'll need to do is update the ODBC-drivers to the latest version (7.1 or 7.1.1) by uninstalling the older ODBC drivers and then reinstalling the newer 7.1.1 ones..

Then, the connection string I used to succesfully connect via PowerBI was in the form of

```
192.168.56.117/E625D0BDD8A975CBC7001B842EAEFB56CDCC664459AE21BFAFCA13D9495D4D77:8563
```

so hostname / fingerprint : port

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 