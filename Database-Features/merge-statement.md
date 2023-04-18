# MERGE Statement 
## Background

MERGE is designed to use a small UPDATE table to affect a larger FACT table. 

## Explanation

## Merge, standard edition

 This scenario primarily uses values from the UPDATE table and their primary key in the FACT table to

* insert new rows based on values from the UPDATE table
* update values in the FACT table according to values from both tables
* delete rows from the FACT table according to conditions based on both tables


```markup
MERGE INTO customers c
USING new_customers n
ON
(n.customer_no = c.customer_no)
WHEN MATCHED THEN
    UPDATE SET
    city_id=n.city_id
WHEN NOT MATCHED THEN
    INSERT VALUES
    (customer_no, first_name, last_name, gender, birthday, city_id);
```
## Merge, reversed scenario

During ETL and quality assurance, MERGE can be used to apply constraint checks on a temporary table.

In this scenario, the large FACT table acts as source for modifications in the STAGING table:

UPDATE/DELETE rows that violate primary key or other logical constraints that need cross-referencing with data from the FACT table.

INSERT actions generally are not desired in this scenario, most cases can even be replaced with corresponding UPDATE TABLE statements using EXISTS or IN(SELECT) constructs. The advantage of MERGE here is the possibility to update the target table with the data from the source table:


```markup
MERGE INTO new_customers n
USING customer c
ON( c.customer_no=n.customer_no )
WHEN MATCHED THEN
	UPDATE
	SET error_flag=true,
	error_text= 'Customer-id already exists with name ' || c.first_name || ',' ||c.last_name
	WHERE
	c.first_name||c.last_name != n.first_name||n.last_name;
```
## Merge as difference-finder

MERGE can also be used to detect differences between tables.

Assume you need to find all differences between today's and yesterday's excerpt of customers.

Normally, you would

* do a LEFT OUTER JOIN to find new (primary key) rows,
* do a RIGHT OUTER JOIN to find deleted (primary key) rows and
* do a INNER JOIN with filters to find modified (non primary key) rows.

All three steps can be done with a single MERGE command, but in this case it's destructive on one of the two tables:

* Add a 'status' column to today's table
* MERGE yesterday's table into today's table:
	+ INSERT all all non-matching rows (these have obviously been deleted since yesterday)
	+ UPDATE the status column of all matching rows (they are potentially modified), but DELETE all the rows that do not differ between the two tables (they are unmodified and therefore uninteresting)

All untouched rows (status-column is still default value) had no match in yesterday's data and are obviously new to the table.

The result you can now feed to 'Merge, the standard edition' and update your FACT table with that.


```markup
MERGE INTO new_customer n
USING customer c
ON
(c.customer_no=n.customer_no)
WHEN MATCHED THEN
    UPDATE SET
    status_flag='U'
         DELETE WHERE
        (c.first_name=n.first_name AND ... AND c.city_id=n.city_id)
WHEN NOT MATCHED THEN
     INSERT VALUES
     (customer_no, first_name, ..., city_id, 'D')
;
```
Result: * Rows, that have been deleted since the previous day, did not exist in the table „today" anymore and were reinserted by applying the INSERT rule and bear the status_flag „D" for delete.
* Rows that still exist, receive the flag „U" for update by applying the UPDATE rule.
* Rows that did not change to the previous day are directly being deleted from the table „today" by applying the DELETE rule.
* Newly added rows that did not yet exist in „yesterday", remain unaffected by the merge and exclusively bear the default status flag (if applicable NULL).

## Merge using sub-selects

Sometimes the update table must be generated dynamically. A sub-select can be used for this purpose.


```markup
MERGE INTO NYC_TAXI_STAGE.TRIP_LOCATION_ID_MAP insert_target
USING   (SELECT  DISTINCT t.id,
                zd.location_id dropoff,
                zp.location_id pickup
        FROM NYC_TAXI_STAGE.TRIPDATA t
        JOIN NYC_TAXI_STAGE.TRIP_LOCATION_ID_MAP m    ON m.trip_id = t.id 
        JOIN NYC_TAXI.TAXI_ZONES zp                   ON ST_within(t.pickup_geom, zp.polygon) = true
        JOIN NYC_TAXI.TAXI_ZONES zd                   ON ST_within(t.dropoff_geom, zd.polygon) = true)
        subselect
ON      insert_target.trip_id = subselect.id
WHEN MATCHED THEN 
        UPDATE SET dropoff_location_id = dropoff,
                   pickup_location_id  = pickup;

```
Notes:

* Aliases inside and outside of the sub-select are in separated namespaces. Even if both occurrences of TRIP_LOCATION_ID_MAP would have the same alias  
 
```
MERGE INTO NYC_TAXI_STAGE.TRIP_LOCATION_ID_MAP m ...  
JOIN NYC_TAXI_STAGE.TRIP_LOCATION_ID_MAP m ...
```
 Both aliases are still necessary in order for the compiler to address both tables.
* In the statement above 
```
JOIN NYC_TAXI.TAXI_ZONES zp ON ST_within(t.pickup_geom, zp.polygon) = true  
JOIN NYC_TAXI.TAXI_ZONES zd ON ST_within(t.dropoff_geom, zd.polygon) = true
```
 can have multiple cases where the join condition is **True** (these conditions check if a geographical point is inside an area but the areas overlap which means that a point sometimes in in two areas). This would cause the UPDATE to fail because in order to do an update based on a JOIN condition there must be only on case in which the condition evaluates to **True**. To fix this, a SELECT DISTINCT t.id is used to make sure that only one row remains after all joins are evaluated.
* You might have noticed that 
```
 JOIN NYC_TAXI_STAGE.TRIP_LOCATION_ID_MAP m ON m.trip_id = t.id 
```
 and 
```
... ON insert_target.trip_id = subselect.id
```
 do essentially the same thing. Yet both conditions are mandatory. It might seem that an **ON true** would be sufficient in this case because both JOIN conditions yield the same results. **The MERGE statement does not allow always true conditions**. Therefore the join has to be performed twice. In this special case it makes sense anyway because by using DISTINCT in the sub-select a materialization is created which makes re-evaluation of the joins necessary.

## Additional References

* [MERGE Syntax](https://docs.exasol.com/sql/merge.htm)
