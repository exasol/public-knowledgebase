# How to load bad CSV files
## Background

CSV is a very common format for inter platform data transfer. Unfortunately, it is not well defined. In this article we want to briefly explain how to handle CSV files that cannot be loaded into Exasol out-of-the-box.

Exasol import command defaults:

* UTF-8
* comma between the fields
* Linux linefeed (LF)
* date and timestamp format as in your database
* fields with special characters are enclosed with double quotes ("), if this character is part of a field it has to be doubled ("")
* no extra line with column names or other headers
* null is an empty field

Import command parameters:

* encoding
* column separator
* row separator
* column delimiter
* format
* skip
* null

## Explanation

:x: **What typically happens (CSV Import Cheat Sheet):** <br />
:heavy_check_mark: **Solution**

:x: encoding is different to what you expected <br />
:heavy_check_mark: use the encoding parameter (e.g. ENCODING='Latin-1')

:x: fields are not separated with commas <br />
:heavy_check_mark: use the column separator parameter (e.g. COLUMN SEPARATOR='|')

:x: the file has been created on Windows <br />
:heavy_check_mark: use the row separator parameter (ROW SEPARATOR='CRLF')

:x: date or timestamp format differ from you database settings <br />
:heavy_check_mark: change the database settings (e.g. ALTER SESSION SET NLS_DATE_FORMAT='DD.MM.YYYY') <br />
:heavy_check_mark: use the format parameter (e.g. FORMAT='DD.MM.YYYY'); especially if there are different formats within one file!

:x: The file has a header (e.g. with general file information or column names) <br />
:heavy_check_mark: use the skip parameter to skip the number of lines (e.g. SKIP=1 to skip only the first line)

:x: The file contains additional columns <br />
:heavy_check_mark: list the columns that you want to import (e.g. ...FILE='data.csv'(1..10,12..15,17)... )

:x: Not all columns of a table are in the file <br />
:heavy_check_mark: list all target columns that you want to load (e.g. IMPORT INTO tab(c1,c2,c4,c8)...)

:x: Null is not an empty field but something like \N or _NULL_ <br />
:heavy_check_mark: use the null parameter (e.g. NULL='\N')

:x: Invalid data for a target data type (e.g. date 0000-00-00) <br />
:heavy_check_mark: Load the data into varchar, modify the values and change the data type afterwards

:x: Missing date part in a timestamp column (maybe because source used time data type) <br />
:heavy_check_mark: Load the data into varchar, add the date part from another column or set it to a default by string concatenation and change the data type to timestamp afterwards
