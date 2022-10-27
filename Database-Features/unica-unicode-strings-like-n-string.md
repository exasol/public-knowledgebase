# Unica: Unicode Strings like N'String' 
## Background

Syntax error when using Unica Campaign with Unicode strings:  
Error:[42000]syntax error, unexpected simple_string_literal, expecting

## Explanation

Unica campaign sends Unicode strings like N'String' to the database. Exasol does not support this syntax. Set property  
'ODBCUnica' : disabled in Unica.

## Additional References

[Problems-with-special-characters-utf-8-in-php-using-unixodbc](https://community.exasol.com/t5/connect-with-exasol/problems-with-special-characters-utf-8-in-php-using-unixodbc/ta-p/1049) 

