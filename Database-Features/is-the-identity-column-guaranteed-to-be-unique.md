# Is the IDENTITY Column guaranteed to be unique? 
## Question

Is the IDENTITY Column guaranteed to be unique?

## Answer

Even though your use case scenario may not apply here, the uniqueness is NOT guaranteed as you can UPDATE the IDENTITY column. The way around this is to make the IDENTITY column a primary key. Probably not doable for most production database repositories.

We discussed the content in <https://docs.exasol.com/sql_references/data_types/identitycolumns.htm>

specifically, the part, "*Identity columns cannot be considered as a constraint, that is, identity columns do not guarantee unique values. However, the values are unique as long as they areinserted implicitlyand are not manually changed*." This means a series of concurrent inserts where the IDENTITY is not included in the values inserted, then the FIFO rule applies, where the first insert does a commit and generates the IDENTITY, then the next insert is free to insert. The emphasis is on the*insert implicitly*- where the IDENTITY value is not specified, but system generated. If you do an insert with the IDENTITY value coded in the insert statement if will insert and become a duplicate. Remember, the IDENTITY column can't be considered a constraint.

There are a couple of suggestions to get closer to guaranteed uniqueness:  
1. LOCK the table you are inserting into - which means no one can insert until you either commit or rollback. This can be achieved with:  
DELETE FROM &lt;tableName&gt; where FALSE;  
2. Do the insert  
3. Release lock with commit or rollback.

Another suggestion is to create a function to insert the max(ROW_NUMBER()) + 1 into the IDENTITY column. It's at the bottom of this simple example SQL.


```
drop schema exa_29444 CASCADE; 
commit; 
create schema exa_29444; 
open schema exa_29444; 

-- Build a test table with an IDENTITY column.  

create or replace table identity_test (id int identity, name varchar(20)); 

-- optional TRUE constraint for IDENTITY COLUMN  

--alter table identity_test add constraint it_pk PRIMARY KEY ("ID") enable;


-- Load the table with data using**IMPLICIT insert**on IDENTITY Column "ID"  

insert into identity_test (name) values ('Zach'),('Cole'),('Daniel'); 
commit; 

-- Present the results  

SELECT * FROM IDENTITY_TEST; 
 
-- Template to generate the next sequential ID - using ROW_NUMBER analytic function.  
–- If you wish to Generate the IDENTITY COLUMN value for the insert (Explicit insert)  

WITH ROWZ (RowNumber) AS (select ROW_NUMBER() over (ORDER BY ID ASC) RowNumber 
  FROM IDENTITY_TEST)  SELECT MAX(RowNumber) +1 from ROWZ; 
commit; 
```
## Additional References

 <https://docs.exasol.com/sql_references/data_types/identitycolumns.htm>

<https://docs.exasol.com/sql/alter_table(column).htm>

<https://docs.exasol.com/sql_references/metadata/metadata_system_tables.htm>

*We appreciate your input! Share your knowledge by contributing to the Knowledge Base directly in [GitHub](https://github.com/exasol/public-knowledgebase).* 