# Why I get Lua Error "decimal expected, got number"?

## The Problem

I have the following TEST-Data:

```sql
CREATE SCHEMA IF NOT EXISTS TEST;
CREATE OR REPLACE TABLE test.T (a DECIMAL(18,0));
INSERT INTO test.T VALUES (100.5);
```

and the following LUA-UDF defined:

 ```lua
CREATE OR REPLACE LUA SCALAR SCRIPT TEST.NUMBER_DECIMAL_UDF (a DECIMAL(18,0))
EMITS (b DECIMAL(18,0)) as
function run(ctx)
  b = ctx.a / 10
  ctx.emit(b)
end
```

When I execute it

```sql
SELECT TEST.NUMBER_DECIMAL_UDF (a) FROM TEST.T;
```

I get the following error message:

```sql
[Code: 0, SQL State: 22001] Lua Error "decimal expected, got number" caught in script "TEST"."NUMBER_DECIMAL_UDF" at line 4 (Session: 1836005522647613440)
```

## The Error

We get "decimal expected, got number" error in this Exasol Lua UDF because Exasol's UDF environment treats DECIMAL types very strictly, and the result of a division operation (/) in Lua, even between two numbers that originated as DECIMAL, will default to a standard Lua number (which is a floating-point double).

The output (EMIT) expect an instance of decimal object, this means a value of the same type as the column declared (b DECIMAL(18,0)) but it is passing a standard Lua number (e.g., 20, 5.03) via ctx.emit.

## The Solution

Wrap your value using decimal() provided by Exasol’s Lua integration to explicitly convert your Lua numbers into the decimal type:

```lua
CREATE OR REPLACE LUA SCALAR SCRIPT TEST.NUMBER_DECIMAL_UDF (a DECIMAL(18,0))
EMITS (b DECIMAL(18,0)) as
function run(ctx)
  local b_float = ctx.a / 10 -- This will result in a Lua 'number' (float)
  local b_integer = decimal(b_float,18,0) -- Convert to integer (truncates decimal part)
  ctx.emit(b_integer) -- Emit the integer
end
```

### Explanation

* ctx.a / 10: Performs floating-point division in Lua.
* DECIMAL(): Converts the floating-point result into an integer by rounding down

### Hint

❗ Always use decimal() for calculations if you’re working with DECIMALs! ❗

## References

* [Exasol Lua Scripting: Decimal number handling](https://docs.exasol.com/db/latest/database_concepts/scripting/general_script_language.htm#TypesandValues)

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).*
