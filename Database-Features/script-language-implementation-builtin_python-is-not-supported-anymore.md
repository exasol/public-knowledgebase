# Script language implementation "builtin_python" is not supported anymore

## Problem

After the upgrade of Exasol cluster to 7.1.20 and higher the following UDF is failing:

```SQL
--/
CREATE OR REPLACE PYTHON SCALAR SCRIPT TEST."PHYTHON_TEST" () RETURNS INT AS
def run(ctx):
  return 1
;
```

select TEST."PHYTHON_TEST"() ;

```SQL
Error Code: 22064 Error Message: Script language implementation "builtin_python" is not supported anymore. Please consider switching to Python3. If this is not possible at all, please contact Exasol support." caught in script "Schema_1"."Script_1" at line 137 (Session: 1835276087831811338), SQLSTATE [43000]
```

## Explanation

Python 2 is no longer available by default and has been hidden on existing systems updated to versions 7.1.20 and onwards. Support for Python2 was discontinued on January 1st, 2020. Thus, Exasol can no longer provide a secure Python 2 container.

All our latest Script Language Containers on GitHub have Python 2 removed already.

* The PYTHON alias for the script language was removed.
* The PYTHON3 alias was updated to a new container version's location.

## Solution

### Convert to Python3

Convert **PYTHON** alias to **PYTHON3** alias.

Example:

```SQL
--/
CREATE OR REPLACE PYTHON3 SCALAR SCRIPT TEST."PHYTHON_TEST" () RETURNS INT AS
def run(ctx):
  return 1
;
```

#### Pre-update check


We have developed a procedure, which can be found in the “Pre-update Check” chapter in  [Using Python 2 with Exasol 7.1.20 or later | Exasol DB Documentation](https://docs.exasol.com/db/7.1/database_concepts/udf_scripts/python2_extended_use.htm#UpdateFrom71xTo7120ornewer), that you can use to check whether you have existing Python 2 scripts running, in case you want to check your system and start converting Python 2 scripts to Python 3.

#### ⚠ DISCLAIMER ⚠

* Please also note that the procedure described in the link above lists the majority but not all such User Defined Functions, especially when Python 2 was not used via the macro "builtin_python".
* Some modules and/or methods changed their names, some syntactic constructs allowed by Python 2 don't work in Python 3 anymore etc. The topic of detailed differences between Python versions belongs to Python itself and is out of scope for Exasol documentation.

### Restore Python2

If it's not possible to convert Python 2 scripts to Python 3, then you can restore the PYTHON alias by setting a parameter to the old container. The procedure is described in in chapter “Update From 7.1.x To 7.1.20 or newer” in [Using Python 2 with Exasol 7.1.20 or later | Exasol DB Documentation](https://docs.exasol.com/db/7.1/database_concepts/udf_scripts/python2_extended_use.htm#UpdateFrom71xTo7120ornewer).


## References

* [CHANGELOG: Python 2 removed from Script Language Containers](https://exasol.my.site.com/s/article/Changelog-content-16903)
* [Using Python 2 with Exasol 7.1.20 or later | Exasol DB Documentation](https://docs.exasol.com/db/7.1/database_concepts/udf_scripts/python2_extended_use.htm#UpdateFrom71xTo7120ornewer)
* [Sunsetting Python 2](https://www.python.org/doc/sunset-python-2/#:~:text=The%20sunset%20date%20has%20now,when%20we%20released%20Python%202.7.)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
