# Casting Shorter GUID as Hashtype

## Question
For readability and performance, I have some shorter GUID-style identifiers (slugs, whatever) containing [0-9][A-F] characters

These cannot be inserted into HASHTYPE(16 BYTE) without padding.
```
-- failed  
SELECT CAST(UCASE('550E8400E') AS HASHTYPE(16 BYTE)) STUDYID  
FROM DUAL

-- success  
SELECT CAST(UCASE('550E8400E00000000000000000000000') AS HASHTYPE(16 BYTE)) STUDYID  
FROM DUAL
```

## Answer
A workaround to try:

> (CAST(RPAD(PROCESSINGID,32,'0') AS HASHTYPE(16 BYTE))

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 