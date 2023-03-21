# Querying and Converting JSON Data with the JSON_TABLE UDF 
## Problem

JSON data that is stored in EXASOL tables can be accessed through UDFs. JSON documents can be accessed through *path expressions*.

To understand what path expressions are, let us have a look at the following JSON document:


```"code
{ "name": "Bob", "age": 37, "address":{"street":"Example Street 5","city":"Berlin"}, "phone":[{"type":"home","number":"030555555"},{"type":"mobile","number":"017777777"}], "email":["bob@example.com","bobberlin@example.com"] } 
```
The JSON document contains five fields: “name” (a string), “age” (an integer), “address” (a document), “phone” (an array containing documents) and “email” (an array containing strings).

Path expressions start with a dollar sign ($) representing the root document. The dot operator (.) is used to select a field of a document, the star in box brackets ([*]) selects and unnests all elements of an array. The following path expression finds all phone numbers:


```"code
$.phone[*].number 
```
This expression is evaluated as follows:

|path step   |result   |
|---|---|
|```$```   |```{ "name": "Bob", "age": 37, "address":{"street":"Example Street 5","city":"Berlin"},```<br />```"phone":[{"type":"home","number":"030555555"},{"type":"mobile","number":"017777777"}],```<br />```"email":["bob@example.com","bobberlin@example.com"] }```   |
|```$.phone```   |```[{"type":"home","number":"030555555"},{"type":"mobile","number":"017777777"}]```   |
|```$.phone[*]```   |```{"type":"home","number":"030555555"}```<br />```{"type":"mobile","number":"017777777"}```   |
|```$.phone[*].number```|```"030555555"```<br />```"017777777"``` |

## Solution

This solution presents a generic Python UDF json_table to access field values in JSON documents through *path expressions*.

The json_table function has the following form:


```"code
select json_table(  
 <json string or column>,  
 <path expression>,  
 <path expression>,  ... 
 ) emits (<column_name> <data_type>, <column_name> <data_type>, ...) 
```
The JSON_TABLE UDF attached to this solution takes a VARCHAR containing JSON data as a first parameter and one or more path expressions:


```"code
create or replace python scalar script json_table(...) emits(...) as 
```
The function can be called in a SELECT query. The EMITS clause has to be used to define the output column names and their data types.


```"code
SELECT json_table('{ "name": "Bob", "age": 37, "address":{"street":"Example Street 5","city":"Berlin"},  
"phone":[{"type":"home","number":"030555555"},{"type":"mobile","number":"017777777"}], 
"email":["bob@example.com","bobberlin@example.com"]}','$.phone[*].number') EMITS (phone VARCHAR(50)); 
```
When the JSON data is stored in a table, the first parameter of JSON_TABLE contains the column name:


```"code
CREATE TABLE example_table (column_a INT, json_data VARCHAR(2000000)); 
-- INSERT INTO example_table VALUES (1, '{ "name": "Bob",…'); (as above) 
SELECT json_table(json_data,'$.phone[*].number') EMITS (phone VARCHAR(50)) FROM example_table; 
```
It is possible to use both the json_table UDF and normal columns of the table within the SELECT clause:


```"code
SELECT column_a, json_table(json_data,'$.phone[*].number') EMITS (phone VARCHAR(50)) 
FROM example_table; 
```
When a row in the input table consists of n phone numbers within the JSON column, there will be n output rows for that tuple. The value of column_a is constant for all those rows:



| COLUMN_A | PHONE |
| --- | --- |
| 1 | 030555555 |
| 1 | 017777777 |

The following table shows some more valid path expressions:

|path   |result   |
|---|---|
|```$.name```   |```"Bob"```   |
|```$.address```   |```{"street":"Example Street 5","city":"Berlin"}```   |
|```$.address.city```   |```"Berlin"```   |
|```$.email```   |```["bob@example.com","bobberlin@example.com"```]   |
|```$.email[*]```   |```"bob@example.com"```<br /> ```"bobberlin@example.com"```   |

This query converts the JSON data into column values:


```"code
SELECT json_table(json_data,'$.name', '$.age', '$.address.city') 
EMITS (name VARCHAR(500), age INT, city VARCHAR(500)) 
FROM example_table; 
```


| NAME | AGE | CITY |
| --- | --- | --- |
| Bob | 37 | Berlin |

When unnesting an array, the values from different levels stay the same for every array element:


```"code
SELECT json_table(json_data,'$.name', '$.age', '$.address.city', '$.email[*]') 
EMITS (name VARCHAR(500), age INT, city VARCHAR(500), email VARCHAR(500)) 
FROM example_table; 
```


| NAME | AGE | CITY | EMAIL |
| --- | --- | --- | --- |
| Bob | 37 | Berlin | bob@example.com |
| Bob | 37 | Berlin | bobberlin@example.com |

The result of unnesting more than one array is the cross product of those arrays:


```"code
SELECT json_table(json_data,'$.name', '$.age', '$.address.city', '$.email[*]', '$.phone[*].type', '$.phone[*].number') 
EMITS (name VARCHAR(500), age INT, city VARCHAR(500), email VARCHAR(500), phone_type VARCHAR(50), phone_number VARCHAR(50)) 
FROM example_table; 
```


| NAME | AGE | CITY | EMAIL | PHONE_TYPE | PHONE_NUMBER |
| --- | --- | --- | --- | --- | --- |
| Bob | 37 | Berlin | bob@example.com | home | 030555555 |
| Bob | 37 | Berlin | bob@example.com | mobile | 017777777 |
| Bob | 37 | Berlin | bobberlin@example.com | home | 030555555 |
| Bob | 37 | Berlin | bobberlin@example.com | mobile | 017777777 |

Details and limitations:

* When the JSON input is not a single document but an array, the elements of the array can be accessed via $[*]
* It is recommended to use the correct data types in the EMITS clause. Otherwise, casting is done which can lead to type-conversion errors.
* When accessing non-atomic values, i.e. arrays without unnesting them, or documents, they are returned as a VARCHAR containing the result in JSON format.
* Accessing multi-dimensional arrays is not supported. This means, at most one [*] can be used in a path expression.

## Additional References

<https://docs.exasol.com/advanced_analytics/accessing_json_data_udfs.htm>

<https://docs.exasol.com/sql_references/functions/alphabeticallistfunctions/json_value.htm>

<https://exasol.my.site.com/s/article/Parsing-JSON-data-with-python>

<https://docs.exasol.com/db/latest/sql_references/functions/json.htm>

