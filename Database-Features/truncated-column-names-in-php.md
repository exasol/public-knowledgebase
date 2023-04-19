# Truncated Column Names in PHP 
## Problem

When reading ODBC result sets in PHP, column names are truncated to 32 characters

This is not a fault in the driver or communication, but a built-in limitation in the php code.

## Solution

Compile PHP from source code after editing file ...&lt;php-dir&gt;/ext/odbc/php_odbc_includes.c:

In "struct odbc_result_value", increase size of "char name[32]" to your needs.

