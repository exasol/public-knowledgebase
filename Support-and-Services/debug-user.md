# Debug User for Exasol Support  


## Background

If an analysis of system dictionaries is required for trouble shooting or correction work, we usually login to the database by using a special database user, whose access privileges are limited to system dictionaries. Thus, direct access to the data tables of the database is not possible.
## Explanation

You can use the below SQL Statements to create the user with the necessary permissions. Once the user is created, please share the password with Exasol support in a secure way.

- Exasol versions &lt; 6.1:
```
    CREATE USER exa_debug IDENTIFIED BY "secure password";
    GRANT CREATE SESSION TO exa_debug;
    GRANT SELECT ANY DICTIONARY TO exa_debug;
```
- Exasol versions &gt;= 6.1:
```
    CREATE USER exa_debug IDENTIFIED BY "secure password";
    GRANT CREATE SESSION TO exa_debug;
    GRANT SELECT ANY DICTIONARY TO exa_debug;
    GRANT EXPORT TO exa_debug;
```
## Additional References

[Access to data](https://docs.exasol.com/db/latest/planning/support.htm) 

[Overview of Professional Services](https://www.exasol.com/product-overview/customer-support/)


