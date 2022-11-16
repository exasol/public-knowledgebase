# GeoJSON in Exasol

## Question
We are on EXASOL v7 and we are desperatly trying to import geojson-data in our database.
Unfortunatly the Solution described for the JSON_TABLE UDF (https://docs.exasol.com/sql_references/geospatialdata/import_geospatial_data_from_csv.htm) is not working for us.
The newest version of the script is download from github and placed in "EXA_TOOLBOX". I get the following - not very telling - error:

SELECT exa_toolbox.json_table('{ "name": "Bob", "age": 37, "address":{"street":"Example Street 5","city":"Berlin"},
"phone":[{"type":"home","number":"030555555"},{"type":"mobile","number":"017777777"}],
"email":["bob@example.com","bobberlin@example.com"]}','$.phone[*].number') EMITS (phone VARCHAR(50));

> [Code: 0, SQL State:22002] VM error: F-UDF-CL-LIB-1125: F-UDF-CL-SL-PYTHON-1000: F-UDF-CL-SL-PYTHON-1005: SyntaxError: invalid syntax

Since v7 supports native JSON-Functions we gave the JSON_EXTRACT a go. This generally works but we are not able to extract "arrays" (the coordinates of the
polyon in geojson) from the json? We get the following error for which i cannot find a solution :disappointed_face:

import into geo_import from local CSV file 'custom.geo.json' column separator = '0x01' column delimiter = '0x02';

create or replace view geojson as
select JSON_EXTRACT(v, '\$.features[*].properties.name', '\$.features[*].geometry')
emits (name varchar(2000000), geojson varchar(2000000)) from geo_import;
select * from geojson limit 10;

> [Code: 0, SQL State:22002] data exception - SQL/JSON scalar required in column: GEOJSON

## Answer
Please take a look at these:

https://docs.exasol.com/sql_references/functions/json_path_expressions.htm#CategoryJSONEXTRACTExtens... for the # path extension.

https://docs.exasol.com/sql_references/functions/json_path_expressions.htm#CategoryExasolExtensions for the json() extension.

And try this:
```
create table tj(x varchar(2000000));  
import into tj from local CSV file 'C:\Users\fs\Desktop\custom.geo.json' column separator = '0x01' column delimiter = '0x02';  

select JSON_EXTRACT(x, '$.features[*]#.properties.name', '$.features[*]#.geometry.json()')
emits (name varchar(2000000), geojson varchar(2000000)) from tj;
```
