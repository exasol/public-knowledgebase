# Resolving ETL-3002: Invalid Byte Stream Error During CSV Import

## Overview

`ETL-3002` indicates that Exasol could not decode the input data using the character encoding configured for the import.

For CSV and FBV imports, Exasol uses UTF-8 by default. If the source file uses another encoding—for example, ISO-8859-1 or WINDOWS-1252—bytes representing special characters may not be valid UTF-8. Exasol then rejects the affected rows and reports:

```text
ETL-3002: Invalid byte stream for UTF-8 encoding.
Please check the encoding setting and the input data
```

This article focuses on CSV and FBV file imports.

## Example scenario

Consider a file encoded as ISO-8859-1 containing:

```text
1,Brötchen
```

In ISO-8859-1, `ö` is represented by the single byte `F6`. In UTF-8, the same character is represented by the two-byte sequence `C3 B6`.

If Exasol reads the ISO-8859-1 file as UTF-8, byte `F6` is not a valid UTF-8 start byte. The row is rejected.

An error table may contain data similar to the following:

```text
ROW_NR:     0
ERROR_TEXT: col 1: ETL-3002: Invalid byte stream for UTF-8 encoding...
TRUNCATED:  false
CSV_DATA:   31 3B 42 72 F6 74 63 68 65 6E
```

The hexadecimal data corresponds to `1;Brötchen` in ISO-8859-1. The byte `F6` identifies the character causing the UTF-8 decoding failure.

## Solution

### 1. Identify the actual file encoding

Determine the encoding from the system or application that created the file. Do not rely only on the file extension or the term “ANSI”, because “ANSI” is not one unique character encoding.

Common possibilities include:

- `UTF-8`
- `ISO-8859-1`
- `WINDOWS-1252`
- `IBM850`

If the file originates from a Windows application and may contain characters such as the euro sign or typographic quotation marks, `WINDOWS-1252` may be more appropriate than `ISO-8859-1`.

### 2. Specify the encoding in the IMPORT statement

The `ENCODING` option tells Exasol how to decode the CSV file. It does not change the source file itself; Exasol decodes the input and stores the resulting text in the target column.

```sql
CREATE SCHEMA IF NOT EXISTS test;

CREATE OR REPLACE TABLE test.test_import_encoding (
    id      DECIMAL(10, 0),
    content VARCHAR(20) UTF8
);

IMPORT INTO test.test_import_encoding
FROM LOCAL CSV FILE '/path/to/test_error.csv'
    ENCODING = 'ISO-8859-1'
    ERRORS INTO test.test_import_errors (CURRENT_TIMESTAMP)
    REJECT LIMIT UNLIMITED;
```

Exasol supports several encoding names, including `ISO-8859-1`, `WINDOWS-1252`, and `UTF-8`. See the [Supported encodings for ETL](https://docs.exasol.com/db/latest/loading_data/etl_encodings.htm) documentation.

## Error-table handling

When `ERRORS INTO` is specified, Exasol writes rejected rows and diagnostic information to the error table.

`REJECT LIMIT UNLIMITED` allows the import to continue while collecting all invalid rows. Always check the error table after the import:

```sql
SELECT *
FROM test.test_import_errors
ORDER BY ROW_NR;
```

## Recommended validation procedure

1. Test the import with a small sample file containing known special characters, such as `ä`, `ö`, `ü`, `ß`, and `€`.
2. Set `ENCODING` to the encoding actually used by the source file.
3. Check the error table after the import.
4. Verify the imported values
5. Repeat the test with a representative production sample before starting the full import.

## Important limitations

- Changing `ENCODING` cannot repair data that is already corrupted or incorrectly converted in the source file.
- An ASCII-only test file cannot reliably validate the selected encoding. Include non-ASCII characters, such as ä, ö, ü, ß, or €, in the test data.
- A byte sequence can be valid in one encoding and invalid in another. Therefore, the correct encoding must be determined from the source system, not guessed from one character alone.
- Exasol does not support a byte-order mark (BOM) for imported files. Remove the BOM if it causes parsing problems.

## Prevention

- Prefer UTF-8 for newly generated files and interfaces.
- Document the encoding as part of the file-interface specification.
- Configure the producing application explicitly instead of relying on an operating-system default.
- Validate a sample containing special characters before each new data source is introduced.
- Where possible, convert legacy files to UTF-8 before loading them into Exasol.

## References

- [Exasol documentation - IMPORT](https://docs.exasol.com/db/latest/sql/import.htm)
- [Exasol documentation - Supported encodings for ETL](https://docs.exasol.com/db/latest/loading_data/etl_encodings.htm)
- [Exasol documentation - CSV and FBV file formats](https://docs.exasol.com/db/latest/loading_data/file_formats.htm)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
