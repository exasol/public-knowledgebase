# Preprocessor Scripts explained 
## Background

#### What does a preprocessor script do?

Well, it preprocesses

To be more specific, an active preprocessor script is hooked before Exasol's SQL parser. This allows it to intercept and modify any SQL text sent to the database (or executed within a procedure script) before passing it on to the actual parser.

#### What can I do with it?

Those scripts are using the Lua language, so basically you can do anything with the preprocessor; here's a few facts and limitations, though:

* Exasol's Lua library is stripped and can not be extended with binary libraries for security reasons
* Preprocessor scripts do not take parameters; the "current" SQL text can be retrieved through a function call
* Preprocessor scripts**can**execute statements using (p)query
* Preprocessor scripts do not return any values; they "return" the modified SQL text through another function call
* While often preprocessor scripts are enabled on system level, any user can disable this in his or her session (see (2) below)
* Preprocessor scripts are executed in the**caller's context**and privileges. Also, if user can EXECUTE the script (which is a necessity), he/she can also READ it. Security by obscurity won't work.

##### Typical Use Cases

* Compatibility layer for a frontend that produces SQL not suitable for Exasol
* Macro magic: Expanding predefined keywords server-side
* "human knows more" optimizations of queries and filters
* Row-Level Security (    re-read the last two points above)

#### Syntax and Semantics

Please see the Exasol User Manual (Section 3.8) for details.

## Prerequisites

As a preprocessor script is a**schema object**, you will need to find or create a schema to create the script in:


```"code-sql"
create schema if not exists PREPROCESSOR; 
```
**Preconditions:**

* CREATE SCHEMAprivilege**or**pre-existing schema

## How to work with Preprocessor Script?

## Step 1: Safety

"CREATE SCRIPT" statements are also preprocessed. As the preprocessor script you are going to (re-)deploy is very likely to contain the keywords it should react on, it is advisable to disable the preprocessor before deployment:


```"code-sql"
alter session set sql_preprocessor_script = null; 
```
## Step 2: Deploy

Create the preprocessor script. Syntax "around" may depend on the SQL client you are using:


```"code-sql"
--/ create or replace Lua script MY_PREPROCESSOR() as     ...     ...sqlparsing.getsqltext()     ...     ...sqlparsing.setsqltext(...)     ...     return / 
```
**Preconditions:**

* CREATE SCRIPTprivilege
* ownership of the schema**or**CREATE ANY SCRIPTprivilege

## Step 3: Activate locally

Now activate the preprocessor for your local session:


```"code-sql"
alter session set sql_preprocessor_script = PREPROCESSOR.MY_PREPROCESSOR; 
```
## Step 4: TEST IT!

Run a few statements to verify success. Best done with Auditing or Profiling enabled, so you can see the resulting SQL texts.  
When things go very wrong, go back to step (2) – This is the only SQL statement not passed through the preprocessor...

## Step 5: Activate globally

Now that things went well, we can activate the script for other users (new sessions):


```"code-sql"
alter system set sql_preprocessor_script = PREPROCESSOR.MY_PREPROCESSOR; 
```
**Preconditions:**

* ALTER SYSTEMprivilege

## Step 6: No wait, we forgot something important!

We just locked out (more or less) everyone else from the database: They don't haveEXECUTEpermissions on the script!


```"code-sql"
grant EXECUTE on PREPROCESSOR.MY_PREPROCESSOR to public; 
```
**Preconditions:**

* ownership of the schema**or**GRANT ANY OBJECT PRIVILEGEprivilege

## Additional Notes

**Best Practice:**

As step (3) replaces the script, all privileges on it are lost in that step.  
To avoid this problem, the EXECUTE privilege should be put on schema level:


```"code-sql"
grant EXECUTE on SCHEMA PREPROCESSOR to public; 
```
Just make sure you don't put anything dangerous/secret into that schema

## Additional References

* [Preprocessor Scripts Documentation](https://docs.exasol.com/database_concepts/sql_preprocessor.htm)
* [List of functions in Exasol](https://docs.exasol.com/sql_references/functions/all_functions.htm)
* <https://community.exasol.com/t5/database-features/using-the-sql-preprocessor-to-support-postgresql-mysql-functions/ta-p/1041>
