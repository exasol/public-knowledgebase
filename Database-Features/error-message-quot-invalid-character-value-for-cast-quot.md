# Error message &quot;Invalid character value for cast&quot; 
This article describes a solution for exception “**data exception - invalid character value for cast“**

## Scope

You might face the exception “**data exception - invalid character value for cast “** if you are:

* trying to process a number value
* given as varchar/string
* which includes numeric characters only and a group separator and/or decimal character.

## Diagnosis

A **data exception**error has occurred if you receive the following error messages:

```
[Code: 0, SQL State: 22018] data exception - invalid character value for cast; Value: …
```

## **Examples:**

### **Select a Number**


```sql
SELECT TO_NUMBER('1,0420000000000005E+03') TO_NUMBER1;
```
 **Error Message:**

```
[Code: 0, SQL State: 22018]  data exception - invalid character value for cast; 
Value: '1,0420000000000005E+03' (Session: 1714045834776412163)
```

### **Insert into a Table**


```sql
INSERT INTO T VALUES ('9,25');
```
**Error Message:**

```sql
[Code: 0, SQL State: 22018]  data exception - invalid character value for cast; 
Value: '9,25' in write of column T.A (Session: 1714045834776412163)
```
## Explanation

In general, EXASolution does implicit casting. The problem comes from attempting to insert a non-numeric string in a numeric column. The string is converted to a number causes the cast exception to be thrown.

The parameter **NLS_NUMERIC_CHARACTERS** specifies the characters to use as the group separator and decimal character and are used for representing numbers. The group separator separates integer groups (that is, thousands, millions, billions, and so on). The decimal character separates the integer portion of a number from the decimal portion.

Examples:

* The value "3,25" should be inserted in your decimal column. Since **NLS_NUMERIC_CHARACTERS** is set to "**.,**", a period instead of a comma is expected as the decimal separator.
* The value "3.25" should be inserted in your decimal column. Since **NLS_NUMERIC_CHARACTERS** is set to "**,.**", a comma instead of a period is expected as the decimal separator.

## Recommendation

The group and decimal separators are defined in the [**NLS_NUMERIC_CHARACTERS**] (https://docs.exasol.com/sql/alter_session.htm#NLS_NUMERIC_CHARACTERS) parameter and you can check it by doing the below query:


```sql
select * from exa_parameters where PARAMETER_NAME='NLS_NUMERIC_CHARACTERS';
```
If this is not the NLS_NUMERIC_CHARACTERS you need, you can change it as follows:

for the current session using [**ALTER SESSION**] (https://docs.exasol.com/sql/alter_session.htm#ALTERSESSION) 


```sql
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ',.';
```
or for the entire database using [**ALTER SYSTEM**] (https://docs.exasol.com/sql/alter_system.htm#ALTER_SYSTEM)


```sql
ALTER SYSTEM SET NLS_NUMERIC_CHARACTERS = ',.';
```
## Additional References

<https://docs.exasol.com/sql/alter_session.htm#UsageNotes> 

