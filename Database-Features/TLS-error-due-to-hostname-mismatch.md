# TLS Error due to hostname mismatch

## Problem

Sometimes connecting to Exasol DB (after updating the TLS certificates) gives below error.

```text
TLS connection to host (hostname) failed: Hostname mismatch. If you trust the server, you can include the fingerprint in the connection string
```

## Solution

* SubjectAlternativeName parameter in CSR (Certificate Signing Request) should be separated by comma. Error will be raised if comma is missing so please correct it.
* There should not be any space in subject names for eg. ' exasol-test.de', It should be changed to 'exasol-test.de'.

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
