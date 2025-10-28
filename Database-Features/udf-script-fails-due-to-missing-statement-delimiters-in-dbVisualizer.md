# UDF Script Fails Due to Missing Statement Delimiters in DbVisualizer

## Problem

When I execute the following Exasol script in a SQL client such as DbVisualizer:

```sql
CREATE OR REPLACE PYTHON3 SET SCRIPT process(i VARCHAR(2000000))
EMITS (o VARCHAR(2000000)) AS

%perNodeAndCallInstanceLimit 4;

def run(ctx):
    df = ctx.get_dataframe(100000)
    ctx.emit(df)
/
```

I receive the following parsing error:

```text
[Code: 0, SQL State: 42000] Error while parsing %perNodeInstanceLimit option line: 
End of %perNodeAndCallInstanceLimit statement not found (Session: ...)
```

What causes this error, and how can I resolve it?

## Explanation

Standard SQL uses the semicolon (;) for statement termination. When sending complex scripts (such as a UDF with Python code), the SQL client may misinterpret semicolons or other syntax in the code block and try to split the command. This breaks the intended statement, leading to confusing error messages about parsing script options.

## Solution

In DbVisualizer, wrap your entire script with custom delimiters (--/ and /) so the SQL Commander sends everything inside as a single block without splitting:

```sql
--/
CREATE OR REPLACE PYTHON3 SET SCRIPT process(i VARCHAR(2000000))
EMITS (o VARCHAR(2000000)) AS

%perNodeAndCallInstanceLimit 4;

def run(ctx):
    df = ctx.get_dataframe(100000)
    ctx.emit(df)
/
```

### Note

* --/ tells DbVisualizer to treat everything after it—including semicolons inside source code—as one script.
* / at the end marks the end of your script block.

### Summary Steps

* Copy your UDF script.
* Add --/ at the very top and / at the very bottom.
* Execute as a single block in DbVisualizer (or similar SQL Commander).
* This ensures no statement splitting, and your script will parse and execute successfully.

## References

* [Documentation of how to use DbVisualizer with Exasol](https://docs.exasol.com/db/latest/connect_exasol/sql_clients/db_visualizer.htm)
* [Documentation of UDF Instance Limiting](https://docs.exasol.com/db/latest/database_concepts/udf_scripts/udf_instance_limit.htm)
* [Troubleshooting DbVisualizer] (https://docs.exasol.com/db/latest/connect_exasol/sql_clients/db_visualizer.htm#Troubleshooting)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
