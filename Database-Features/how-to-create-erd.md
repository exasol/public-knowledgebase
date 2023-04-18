# How to Create Entity Relationship Diagram from Database

## Question
We'd like to generate an ERD (Entity Relationship Diagrams) by reverse engineering information from Exasol's system tables. Does anybody know a tool which provides this functionality?

## Answer
DBVisualizer and DBeaver can both do this. 

In DBVisualizer you can open the schema, click on Tables, and then click on the References tab.  This will provide a chart that you can save as an EMF file.

The same can be done in DBeaver by again opening your schema, clicking on Tables, and then selecting the ER Diagram tab.