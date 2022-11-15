# How to move a table in Exasol

## Question
Is there any way that I can easily move a table from one Exasol Schema to another in the same server? 

I want to avoid creating the table to another schema and copy there, since is a big table.

## Answer
Since RENAME does not allow to move tables accross schemas I think you'll have to copy the table - I at least don't know of any other way to shift it from one schema to another.

It's probably either CTAS if you have the space "on hand" or EXPORT/DROP/IMPORT if you haven't and can afford to take the table "offline" for a bit.