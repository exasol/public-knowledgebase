## Creating a test table with a specified MEM_OBJECT_SIZE 

This article provides a detailed guide on using the create_table_mem_object_size script to create tables with a specified memory size (MEM_OBJECT_SIZE). It might be useful for Support investigations and experiments.

To use the script, simply create it in your desired schema. Being careful if a table named "dummy" already exists as the script will recreate it. 
The script is designed to create a target table where each row occupies 128 bytes, with randomly generated content ensuring the actual table mem size is 128 bytes times the number of rows. 
The number of rows required to populate the target table is calculated based on the value of the parameter mem_object_size.
To generate a potentially large target table, the script uses a cartesian join of a smaller manageable "dummy" table on itself, multiplying the record count to reach the desired size.   

# script
```sql
create schema test_data_gen;
open schema test_data_gen;

--/
create or replace script create_table_mem_object_size(
        schema_name, table_name,  --target table schema/name
        mem_object_size           --target table desired mem_object_size 
        ) as 
dummy_table_rows_cnt = (math.floor(math.sqrt(mem_object_size * 1024 * 1024 / 128))) + 1

res1 = query([[
DROP TABLE IF EXISTS dummy;
]])

res2 = query([[
CREATE TABLE dummy as
SELECT 1 AS dummy FROM dual CONNECT BY LEVEL <= ]] .. dummy_table_rows_cnt .. [[;
]])

res3 = query([[
CREATE TABLE ]] .. schema_name .. '.' .. table_name .. [[ as
SELECT 
	RAND(1,100) AS rand1, 
	RAND(1,100) AS rand2,
	RAND(1,100) AS rand3,
	RAND(1,100) AS rand4,
	RAND(1,100) AS rand5,
	RAND(1,100) AS rand6,
	RAND(1,100) AS rand7,
	RAND(1,100) AS rand8,
	RAND(1,100) AS rand9,
	RAND(1,100) AS rand10, 
	RAND(1,100) AS rand11,
	RAND(1,100) AS rand12,
	RAND(1,100) AS rand13,
	RAND(1,100) AS rand14,
	RAND(1,100) AS rand15,
	RAND(1,100) AS rand16
	
	--each row takes 128 byte 
FROM 
(SELECT 1 from
test_data_gen.dummy x1,
test_data_gen.dummy x2);
]])
/
```

# Examples

1. 100Mb
```sql
EXECUTE SCRIPT create_table_mem_object_size('test_data_gen', 'tab_100mb', 100) WITH OUTPUT;
--2 second on a basic singlenode vm cluster

select mem_object_size/1024/1024 from exa_all_object_sizes where object_name = 'TAB_100MB' and ROOT_NAME = 'TEST_DATA_GEN'
--result 100.22835159301757812500
```

2. 2Gb
```sql
EXECUTE SCRIPT create_table_mem_object_size('test_data_gen', 'tab_2gb', 2048) WITH OUTPUT;
--40 second on a basic singlenode vm cluster

select mem_object_size/1024/1024 from exa_all_object_sizes where object_name = 'TAB_2GB' and ROOT_NAME = 'TEST_DATA_GEN'
--result 2049.37433147430419921875
```

3. 10Gb
```sql
EXECUTE SCRIPT create_table_mem_object_size('test_data_gen', 'tab_10gb', 10240) WITH OUTPUT;
--4 minutes on a basic singlenode vm cluster

select mem_object_size/1024/1024 from exa_all_object_sizes where object_name = 'TAB_10GB' and ROOT_NAME = 'TEST_DATA_GEN'
--result 10240.29162216186523437500
```
