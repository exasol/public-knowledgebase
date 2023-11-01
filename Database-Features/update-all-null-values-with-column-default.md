# Update all NULL values with column default 
## Problem

We want to replace all NULL values within a certain table with the default value specified for the according column. And we don't want to create the necessary update statements manually.

## Solution

A small metadata-driven procedure script (Lua) that issues the required update statements.  
(See Attachment)

## Notes...

### ...on transactions

The script

* performs a rollback after the metadata request, to avoid a read-write conflict scenario.
* performs all updates within a single transaction.
* will **not abort** when an update on one of the columns fails.
* performs a commit when all columns have been handled, regardless of any errors encountered.

### ...on column selection

The script **includes** all columns that do have a DEFAULT value set.  
It **excludes** all columns with a NOT NULL constraint (ignoring the actual state of the constraint). Obviously, such a column can not contain any NULL values that need updating.

### ...on row selection

Due to Exasol's memory management and data processing, the script handles each column separately. This minimizes both the amount of memory required for processing and the amount of data blocks being written.  
The script does **not** contain any delta functionality, it will process all rows of the table each time it is called.

## Installation

Just create the script in any schema you like (CREATE SCRIPT permission required). It does not have any dependencies.


```sql
create or replace /* procedure */ script REPLACE_NULL( schema_name, table_name ) ... 
```
## Usage

When calling the script, it expects two parameters: A schema name and a table name:


```sql
execute script REPLACE_NULL( 'my schema', 'my table' ); 
```
Both schema and table name are expected as **string** and will be case-sensitive.

## Example


```sql
open schema SR9000;
-- Rows affected: 0

create table Invoice( invoice_id int, invoice_date date default date '2017-01-01' );
-- Rows affected: 0

insert into Invoice values (1, null), (2, null), (3, '2017-02-01');
-- Rows affected: 3

execute script REPLACE_NULL( 'SR9000', 'Invoice' );
-- [43000] "No columns found for "SR9000"."Invoice"" caught in script "SR9000"."REPLACE_NULL" at line 23 (Session: 1585944483210400591
```
... yes. We created the table using a regular identifier, so it ended up as uppercase...


```sql
execute script REPLACE_NULL( 'SR9000', 'INVOICE' ); 
```
This returns:

| --- | --- | --- | --- |
| **COLUMN_NAME** | **COLUMN_TYPE** | **COLUMN_DEFAULT** | **UPDATE_RESULT** |
| INVOICE_DATE | DATE | TO_DATE('2017-01-01','YYYY-MM-DD') | 2 rows updated |

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 