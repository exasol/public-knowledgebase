# Oracle Virtual Schema Datatype Issue

## Question
I have created a view on an Oracle database (date, varchar2 and number data types).

On Exasol I have created a virtual schema and I can see this view as a table. The problem is that all the fields except that date have varchar data type.

How can this be solved?

## Answer
On Oracle if the data type is NUMBER then in Exasol it gets VARCHAR datatype, but if it's NUMBER(2) then in Exasol it gets DECIMAL data type.

If you want to return a DECIMAL type for these types you can set the property like so:

> ALTER VIRTUAL SCHEMA &lt;your-schema-name-goes-here&gt; SET ORACLE_CAST_NUMBER_TO_DECIMAL_WITH_PRECISION_AND_SCALE='36,20';

You´ll also have to refresh the virtual schema afterwards with:

> alter virtual schema &lt;your-schema-name-goes-here&gt; refresh;