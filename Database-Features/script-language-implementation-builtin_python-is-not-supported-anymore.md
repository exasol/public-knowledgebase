# Script language implementation "builtin_python" is not supported anymore

## Problem

After the upgrade of Exasol cluster development team is saying some of their scheduled batch jobs or UDFs are failing.

```SQL
[Exasol][Exasol Driver]"Error while loading TEST_UDF merge2 in LUA_DATA. Error Code: 22064 Error Message: Script language implementation "builtin_python" is not supported anymore. Please consider switching to Python3. If this is not possible at all, please contact Exasol support." caught in script "Schema_1"."Script_1" at line 137 (Session: 1835276087831811338), SQLSTATE [43000]
```

## Explanation

Python 2 is no longer available by default and has been hidden on existing systems updated to versions 7.1.20 and onwards. Support for Python2 was discontinued on January 1st, 2020. Thus, Exasol can no longer provide a secure Python 2 container.

## Solution

### Convert to Python3

Convert **PYTHON** to **PYTHON3**.

Example:

```SQL
--/
CREATE OR REPLACE PYTHON3 SCALAR SCRIPT test."SPLIT" ("myStr" VARCHAR(2000) UTF8) EMITS ("STR" VARCHAR(2000) UTF8) AS
def run(ctx):
  txt = ctx.myStr
  for line in txt.split('|'): 
    ctx.emit(line)
;

select test."SPLIT"('a|b');
```

### Restore Python2

If it's not possible to convert Python 2 scripts to Python 3, then you can restore the PYTHON alias by setting a parameter to the old container. The procedure is described in in chapter “Update From 7.1.x To 7.1.20 or newer” in [Using Python 2 with Exasol 7.1.20 or later | Exasol DB Documentation](https://docs.exasol.com/db/7.1/database_concepts/udf_scripts/python2_extended_use.htm#UpdateFrom71xTo7120ornewer).

### Further background information

You can find further background information on [GitHub](https://github.com/exasol/script-languages-release/releases/tag/2.1.0) and [Exasol's Docs site](https://docs.exasol.com/db/latest/database_concepts/udf_scripts/programming_languages_detail.htm). All our latest Script Language Containers on GitHub have Python 2 removed already. 

On existing installations, the following will happen:

1. The PYTHON alias for the script language will be removed.
2. The PYTHON3 alias will be updated to a new container version's location.
3. The previous container will still be available in BucketFS. It has not been deleted.

We have developed a procedure, which can be found in the “Pre-update Check” chapter in  [Using Python 2 with Exasol 7.1.20 or later | Exasol DB Documentation](https://docs.exasol.com/db/7.1/database_concepts/udf_scripts/python2_extended_use.htm#UpdateFrom71xTo7120ornewer), that you can use to check whether you have existing Python 2 scripts running, in case you want to check your system and start converting Python 2 scripts to Python 3.

DISCLAIMER: Please also note that the procedure described in the link above lists the majority but not all such User Defined Functions, especially when Python 2 was not used via the macro "builtin_python".

## References

* [CHANGELOG: Python 2 removed from Script Language Containers](https://exasol.my.site.com/s/article/Changelog-content-16903)
* [Using Python 2 with Exasol 7.1.20 or later | Exasol DB Documentation](https://docs.exasol.com/db/7.1/database_concepts/udf_scripts/python2_extended_use.htm#UpdateFrom71xTo7120ornewer)
* [Sunsetting Python 2](https://www.python.org/doc/sunset-python-2/#:~:text=The%20sunset%20date%20has%20now,when%20we%20released%20Python%202.7.)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
