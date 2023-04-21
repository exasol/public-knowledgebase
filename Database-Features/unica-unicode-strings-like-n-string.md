# Unica: Unicode Strings like N'String' 
## Background

Syntax error when using Unica Campaign with Unicode strings:  
Error:[42000]syntax error, unexpected simple_string_literal, expecting

## Explanation

Unica campaign sends Unicode strings like N'String' to the database. Exasol does not support this syntax. Set property  
'ODBCUnica' : disabled in Unica.

## Additional References

[Problems-with-special-characters-utf-8-in-php-using-unixodbc](https://exasol.my.site.com/s/article/Problems-with-special-characters-UTF-8-in-php-using-unixODBC) 

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 