# DELETE and INSERT vs. MERGE Performance 
## Question

Scenario: Merge data from a (small) source table into a (big) target table.

The source contains only a few rows (below 10.000, mostly about 1000).  
The target contains some million records.   

**Solution1:**


```
delete from target where id in (select id from source);  
insert into target select * from source;
```
**Solution 2:**


```
merge into target t using source s on (t.id = s.id)  
when matched then update ...  
when not matched then insert;
```
**Questions:**  
Is the merge command more effective than a delete plus insert?  
Is there a need to delete duplicate rows from the source in advance?

## Answer

Testing with a variety of source row sets against a target with about 6 mio. rows showed a slighty time advance using the merge command.

Overall less internal steps are performed in the merge compared to delete/insert. Furthermore the subselect in the delete command will be materialized in a temporary table and then replicated over all nodes, because the number or rows is below the replication border. This causes additional load in the network.

The suggestion is therefore: **use the MERGE command**

Cleaning the source from duplicates is mandatory since the on-condition within the merge-statement needs a unique source rowset.  
Otherwise the exception "Unable to get a stable set of rows in the source tables" will be thrown.

