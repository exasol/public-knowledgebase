# Unicode Support in Exasol 
## Background

Unicode is a computing industry standard (ISO 10646) allowing computers to consistently represent and manipulate text expressed in most of the world's writing systems. With text processing, Unicode takes the role of providing a unique code point - a number, not a glyph - for each character. In other words, Unicode represents a character in an abstract way and leaves the visual rendering (size, shape, font or style) to other software, such as a web browser or word processor.

## Explanation

Unicode has the explicit aim of transcending the limitations of traditional character encodings, which find wide usage in various countries of the world but remain largely incompatible with each other.

Exasol fully supports Unicode and can, therefore, store all the common characters in the database. All identifiers such as schema, table or column names can contain Unicode-characters. You don't need any special settings at table creation (f.e. CREATE TABLE t (v VARCHAR(50)) either. Internally a well-established UTF-8 format will be used, which stores Unicode-characters as variable-length ones. The data type defines the number of symbols that can be stored, not the length in bytes.

On the client-side, the corresponding database driver (f.e. JDBC, ODBC or Client SDK) converts data from local characters set to UTF-8 format and vice versa. Hense the database user can work with the same data by using different character sets without paying any attention to it.

## Additional References

* [SQL Identifiers](https://docs.exasol.com/sql_references/basiclanguageelements.htm#SQLIdentifier)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 