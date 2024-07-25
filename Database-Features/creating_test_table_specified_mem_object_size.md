# Creating a test table with a specified MEM_OBJECT_SIZE

This article provides a detailed guide on using the `create_table_mem_object_size` script to create tables with a specified memory size (MEM_OBJECT_SIZE). It might be useful for Support investigations and experiments.

To use the script, simply create it in your desired schema. Be careful if a table named "dummy" already exists as the script will recreate it. 
The script is designed to create a target table where each row occupies 128 bytes, with randomly generated content ensuring the actual table mem size is 128 bytes times the number of rows. 
The number of rows required to populate the target table is calculated based on the value of the parameter mem_object_size.
To generate a potentially large target table, the script uses a cartesian join of a smaller manageable "dummy" table on itself, multiplying the record count to reach the desired size.   

## script
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
	
	--each row takes 128 byte RAW
FROM 
(SELECT 1 from
test_data_gen.dummy x1,
test_data_gen.dummy x2);
]])



while true do

    res = query([[commit]])
    cur_size = query([[select mem_object_size/1024/1024 as MEM from exa_all_object_sizes where object_name = upper(']] .. table_name .. [[') and ROOT_NAME = upper(']] .. schema_name .. [[') ]])

    if cur_size[1].MEM >= mem_object_size then
        break;
    end
    
    curr_count = query([[select table_row_count as CNT from exa_all_tables where table_name = upper(']] .. table_name .. [[') and table_schema = upper(']] .. schema_name .. [[') ]])
    local add_rows = curr_count[1].CNT * ( mem_object_size - cur_size[1].MEM) / cur_size[1].MEM
    if add_rows < 100 then add_rows = 100 end 
    
    res6 = query([[insert into ]] .. schema_name .. '.' .. table_name .. [[ select * from ]] .. schema_name .. '.' .. table_name .. [[ where rownum <= ]] .. add_rows)
    output('Adding more rows to reach the target MEM_OBJECT ' .. add_rows)
end
/
```

## Examples

1. 100Mb
```sql
drop table test_data_gen.tab_100mb;
EXECUTE SCRIPT create_table_mem_object_size('test_data_gen', 'tab_100mb', 100);
--2 second on a 4 node Saas cluster
select mem_object_size/1024/1024 from exa_all_object_sizes where object_name = 'TAB_100MB' and ROOT_NAME = 'TEST_DATA_GEN'
--result 105.32723617553710937500
```

2. 2Gb
```sql
drop table test_data_gen.tab_2gb;
EXECUTE SCRIPT create_table_mem_object_size('test_data_gen', 'tab_2gb', 2048);
--10 second on a 4 node Saas cluster
select mem_object_size/1024/1024 from exa_all_object_sizes where object_name = 'TAB_2GB' and ROOT_NAME = 'TEST_DATA_GEN'
--result 2048.02326202392578125000
```

3. 10Gb
```sql
drop table test_data_gen.TAB_10GB;
EXECUTE SCRIPT create_table_mem_object_size('test_data_gen', 'tab_10gb', 10240);
--35 seconds on a 4 node Saas cluster
select mem_object_size/1024/1024 from exa_all_object_sizes where object_name = 'TAB_10GB' and ROOT_NAME = 'TEST_DATA_GEN'
--result 10240.88970947265625000000
```
