# Unmatched national characters in regular expressions 
## Background

Regular expressions do not recognize non-ascii national characters in class groups.

Example: 


```"noformat
select regexp_substr('dejá vu', '[[:lower:]]+'); --> "dej"
```
## Explanation

Character groups using [[:group:]] notation are Unicode-unaware as well as highly locale-dependant. Basically, they only work for the ASCII part of Unicode (characters 0 through 127).

As Exasol implements the PCRE syntax for regular expressions, you should use Unicode character classes instead, using \p notation:


```"noformat
select regexp_substr('dejá vu', '[\p{Ll}]+'); --> "dejá" 
```
Here, "Ll" denotes the property (L)etter, (l)owercase.

## Additional References

A list of classes (or character properties) defined by the Unicode standard can be found in Table 12 of document <http://www.unicode.org/reports/tr44/#Property_Values>

