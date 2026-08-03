# Resolving ETL-5106 SSL Certificate Errors with Legacy PyEXASOL

## Overview

PyEXASOL provides several convenient high-performance data transfer methods, including:

- `export_to_list()`
- `export_to_pandas()`
- `export_to_callback()`
- `import_from_pandas()`
- `import_from_iterable()`

Unlike `execute().fetchall()`, these methods **do not transfer data over the existing database connection**. Instead, PyEXASOL starts a temporary local HTTP/HTTPS server and instructs the Exasol database to stream the data directly to that server using internally generated `EXPORT` or `IMPORT` statements over a reverse connection to the client.

Starting with **Exasol 8.32.0 / 2025.1**, TLS certificate validation for HTTP(S)-based ETL connections is enabled by default. Older PyEXASOL versions (for example **0.27.0**) do not generate the required `PUBLIC KEY` clause for these internally generated statements. Consequently, the database cannot validate the temporary HTTPS server certificate and rejects the connection.

As a result, high-performance data transfer methods fail with **ETL-5106**, while ordinary SQL execution continues to work normally.

---

## Symptoms

The following methods may fail:

- `export_to_list()`
- `export_to_pandas()`
- `export_to_callback()`
- `import_from_pandas()`
- `import_from_iterable()`
- other helper methods that internally use `EXPORT` or `IMPORT`

Typical error:

```text
pyexasol.exceptions.ExaQueryError:

ETL-5106:
Following error occured while writing data to external connection

https://<client-ip>:<port>/000.csv failed after 0 bytes.

SSL certificate problem:
self-signed certificate

SSL peer certificate or SSH remote key was not OK
```

Meanwhile,

```python
conn.execute(query).fetchall()
```

continues to work because it uses the already established database connection instead of creating an additional HTTPS transport.

---

## Reproduction

```python
import ssl
import pyexasol
import sys

print("pyexasol:", pyexasol.__version__)
print("Python:", sys.version)
print("OpenSSL:", ssl.OPENSSL_VERSION)

conn = pyexasol.connect(
    dsn="<your_db_host>",
    user="<username>",
    password="<password>",
    encryption=True,
    websocket_sslopt={
        "cert_reqs": ssl.CERT_NONE,
        "check_hostname": False
    }
)

query = "SELECT * FROM dual"

rows = conn.export_to_list(query)
```

The generated SQL is similar to:

```sql
EXPORT (
    SELECT * FROM dual
)
INTO CSV
AT 'https://<client-ip>:<port>'
FILE '000.csv';
```

Notice that **no `PUBLIC KEY` clause is present**.

---

## Root Cause

The issue is caused by the interaction of two independent changes.

### 1. Modern Exasol Versions

Beginning with **Exasol 8.32.0 / 2025.1**, certificate validation for HTTP(S)-based ETL connections is enabled by default.

Whenever the database connects to an HTTPS endpoint using:

- `EXPORT`
- `IMPORT`

it validates the server certificate.

Certificates that cannot be validated are rejected.

---

### 2. Legacy PyEXASOL Versions

PyEXASOL versions prior to **1.0.0** start a temporary HTTPS server using a self-signed certificate.

These versions generate SQL similar to:

```sql
EXPORT ...
AT 'https://...'
```

without adding the required

```sql
PUBLIC KEY 'sha256//...'
```

fingerprint.

The issue is **not simply that the certificate is self-signed**.

Exasol fully supports self-signed certificates when their fingerprint is explicitly provided using the `PUBLIC KEY` clause.

Because legacy PyEXASOL versions omit this clause, the database has no trusted fingerprint available and therefore rejects the certificate during TLS validation.

---

## Solution

### Option 1 (Recommended): Upgrade PyEXASOL

Upgrade to **PyEXASOL 1.0.0 or newer**.

Modern versions automatically determine the fingerprint of the temporary HTTPS server certificate and inject the required `PUBLIC KEY` clause into generated `EXPORT` and `IMPORT` statements.

Upgrade:

```bash
pip install --upgrade pyexasol
```

This is the recommended long-term solution.

---

### Option 2 (Temporary Workaround): Disable Default ETL Certificate Validation

If upgrading PyEXASOL is currently not possible, TLS certificate validation for ETL connections can be disabled on the database.

For example:

```text
-etlCheckCertsDefault=0
```

This restores the behavior of earlier Exasol releases.

> **Warning**
>
> Disabling certificate validation reduces the security of all HTTP(S)-based ETL operations.
> It should only be used as a temporary workaround until the client software can be upgraded.

---

## Affected Versions

| Component | Affected |
|------------|----------|
| Exasol | 8.32.0 / 2025.1 and newer (default TLS validation enabled) |
| PyEXASOL | Versions prior to 1.0.0 |
| Python | Independent of Python version |
| OpenSSL | Independent of OpenSSL version |

---

## Frequently Asked Questions

### Why does `execute().fetchall()` work while `export_to_list()` fails?

Because `execute().fetchall()` uses the existing encrypted database connection.

`export_to_list()` creates a new HTTPS connection between the database and a temporary HTTP(S) server started by PyEXASOL.

Only the latter requires TLS certificate validation.

---

### Why is the error reported as "self-signed certificate"?

The temporary HTTPS server created by PyEXASOL uses a temporary self-signed certificate.

Self-signed certificates are fully supported by Exasol **when the certificate fingerprint is supplied using the `PUBLIC KEY` clause**.

Legacy PyEXASOL versions do not include this clause, so the database has no trusted fingerprint available and rejects the certificate.

---

### Why doesn't `websocket_sslopt` fix the problem?

Because it only controls the client-to-database WebSocket connection.

The failing connection is a completely separate HTTPS connection initiated later by the database during the `EXPORT` or `IMPORT`.

---

## References

- [PyEXASOL Release Notes (v1.0.0)](https://exasol.github.io/pyexasol/master/changes/changes_1.0.0.html)
- [PyEXASOL GitHub Repository](https://github.com/exasol/pyexasol)
- [Exasol CHANGELOG: Default TLS Certificate Validation Enabled for Import/Export Queries](https://exasol.my.site.com/s/article/Changelog-content-25090?language=en_US)
- [Exasol CHANGELOG: TLS Certificate Verification for Loader File Connections (CSV, FBV, LOCAL files)](https://exasol.my.site.com/s/article/Changelog-content-16273?language=en_US)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
