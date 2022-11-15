# How to Debug JVM Crashes

## Question
I'm unable to deploy my RLS variant adapter.  Is there a preferred approach for debugging JVM issues?  The error is:
> VM error: Internal error: VM crashed

## Answer
You can use Java remote debugging to debug any Java UDF.  Have a look here for virtual schemas: https://github.com/exasol/virtual-schemas/blob/master/doc/development/remote_debugging.md 

You can also use the python udf listener and redirect your script output:
https://docs.exasol.com/db/latest/database_concepts/virtual_schema/logging.htm